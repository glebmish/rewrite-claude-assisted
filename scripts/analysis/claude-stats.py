#!/usr/bin/env python3
"""
Claude Log Analysis Script with Subagent Support

Analyzes Claude Code JSONL logs including subagent logs, calculating usage
statistics and costs with per-agent breakdown and proper tool usage ordering.
"""

import argparse
import json
import shlex
import sys
from collections import defaultdict
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# Pricing per million tokens
PRICING = {
    "claude-sonnet-4-5": {
        "input": 3.00,
        "output": 15.00,
        "cache_creation": 3.75,
        "cache_read": 0.30,
    },
    "claude-haiku-4-5": {
        "input": 1.00,
        "output": 5.00,
        "cache_creation": 1.25,
        "cache_read": 0.10,
    },
    "claude-3-5-haiku": {
        "input": 0.80,
        "output": 4.00,
        "cache_creation": 1.00,
        "cache_read": 0.08,
    },
}


@dataclass
class ToolUse:
    """Represents a single tool use."""
    tool_use_id: str
    tool_name: str
    tool_text: str  # Formatted like "Bash('git status')"
    timestamp: str
    is_failed: bool = False
    is_task_call: bool = False
    agent_id: Optional[str] = None  # Set after correlation


@dataclass
class TaskToolCall:
    """Represents a Task tool call that creates a subagent."""
    tool_use_id: str
    subagent_type: str
    description: str
    model: Optional[str]
    timestamp: str
    agent_id: Optional[str] = None  # Populated from tool_result


@dataclass
class AgentUsage:
    """Usage statistics for a single agent (main or subagent)."""
    agent_id: str
    subagent_type: Optional[str] = None  # None for main agent
    description: Optional[str] = None  # None for main agent
    is_sidechain: bool = False
    messages: int = 0
    tool_calls: int = 0
    successful_tool_calls: int = 0
    failed_tool_calls: int = 0
    tools_used: List[str] = field(default_factory=list)  # Ordered list with * prefix for failed
    usage: Dict[str, int] = field(default_factory=dict)  # Token usage
    costs: Dict[str, float] = field(default_factory=dict)  # Costs
    models_used: Dict[str, Dict] = field(default_factory=dict)  # model -> usage/costs breakdown


@dataclass
class SessionAnalysis:
    """Complete analysis of a session including main agent and all subagents."""
    log_file: str
    analysis_timestamp: str
    main_agent: AgentUsage
    subagents: List[AgentUsage] = field(default_factory=list)  # Ordered by first appearance
    totals: Dict = field(default_factory=dict)  # Aggregated metrics
    tools_used_ordered: List[str] = field(default_factory=list)  # Interleaved tool usage


def extract_tool_use(content_item: Dict, timestamp: str) -> ToolUse:
    """
    Extract tool use information and format it nicely.

    Format examples:
    - Bash('git status')
    - Read('/path/to/file.txt')
    - Task('openrewrite-expert')
    - Grep('search pattern')
    """
    tool_id = content_item["id"]
    tool_name = content_item["name"]
    tool_input = content_item.get("input", {})

    # Format based on common input patterns
    if "command" in tool_input:
        tool_text = f"{tool_name}({shlex.quote(tool_input['command'])})"
    elif "file_path" in tool_input:
        tool_text = f"{tool_name}({shlex.quote(tool_input['file_path'])})"
    elif "pattern" in tool_input:
        tool_text = f"{tool_name}({shlex.quote(tool_input['pattern'])})"
    elif "query" in tool_input:
        tool_text = f"{tool_name}({shlex.quote(tool_input['query'])})"
    elif "subagent_type" in tool_input:
        tool_text = f"{tool_name}({shlex.quote(tool_input['subagent_type'])})"
    elif "url" in tool_input:
        # Truncate long URLs
        url = tool_input["url"]
        if len(url) > 50:
            url = url[:47] + "..."
        tool_text = f"{tool_name}({shlex.quote(url)})"
    elif "prompt" in tool_input and tool_name == "SlashCommand":
        # For SlashCommand, show the command
        cmd = tool_input.get("command", "")
        tool_text = f"{tool_name}({shlex.quote(cmd)})"
    else:
        tool_text = tool_name

    is_task_call = tool_name == "Task"

    return ToolUse(
        tool_use_id=tool_id,
        tool_name=tool_name,
        tool_text=tool_text,
        timestamp=timestamp,
        is_task_call=is_task_call,
    )


def extract_task_call(content_item: Dict, timestamp: str) -> TaskToolCall:
    """Extract Task tool call information."""
    tool_input = content_item.get("input", {})
    return TaskToolCall(
        tool_use_id=content_item["id"],
        subagent_type=tool_input.get("subagent_type", "unknown"),
        description=tool_input.get("description", ""),
        model=tool_input.get("model"),
        timestamp=timestamp,
    )


def accumulate_usage(usage_by_model: Dict, model: str, msg_usage: Dict):
    """Accumulate usage statistics by model."""
    if model not in usage_by_model:
        usage_by_model[model] = {
            "input_tokens": 0,
            "output_tokens": 0,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
        }

    usage_by_model[model]["input_tokens"] += msg_usage.get("input_tokens", 0)
    usage_by_model[model]["output_tokens"] += msg_usage.get("output_tokens", 0)
    usage_by_model[model]["cache_creation_input_tokens"] += msg_usage.get(
        "cache_creation_input_tokens", 0
    )
    usage_by_model[model]["cache_read_input_tokens"] += msg_usage.get(
        "cache_read_input_tokens", 0
    )


def calculate_costs(usage: Dict[str, int], model: str) -> Dict[str, float]:
    """
    Calculate costs for given usage and model.

    Args:
        usage: {input_tokens, output_tokens, cache_creation_input_tokens, cache_read_input_tokens}
        model: Model identifier (e.g., "claude-sonnet-4-5-20250929")

    Returns:
        {input_tokens_cost, output_tokens_cost, cache_creation_cost, cache_read_cost, total_cost}
    """
    # Find matching pricing (prefix match)
    pricing = None
    for model_prefix, price in PRICING.items():
        if model.startswith(model_prefix):
            pricing = price
            break

    # Default to sonnet pricing if no match
    if not pricing:
        pricing = PRICING["claude-sonnet-4-5"]

    # Calculate per-category costs
    input_cost = (usage.get("input_tokens", 0) * pricing["input"]) / 1_000_000
    output_cost = (usage.get("output_tokens", 0) * pricing["output"]) / 1_000_000
    cache_creation_cost = (
        usage.get("cache_creation_input_tokens", 0) * pricing["cache_creation"]
    ) / 1_000_000
    cache_read_cost = (
        usage.get("cache_read_input_tokens", 0) * pricing["cache_read"]
    ) / 1_000_000

    total_cost = input_cost + output_cost + cache_creation_cost + cache_read_cost

    return {
        "input_tokens_cost": round(input_cost, 6),
        "output_tokens_cost": round(output_cost, 6),
        "cache_creation_cost": round(cache_creation_cost, 6),
        "cache_read_cost": round(cache_read_cost, 6),
        "total_cost": round(total_cost, 6),
    }


def build_agent_usage(
    agent_id: str,
    messages: List[Dict],
    tool_uses: List[ToolUse],
    usage_by_model: Dict[str, Dict],
    subagent_type: Optional[str] = None,
    description: Optional[str] = None,
    is_sidechain: bool = False,
) -> AgentUsage:
    """Build AgentUsage object from parsed data."""
    # Count successful and failed tools
    successful = sum(1 for t in tool_uses if not t.is_failed)
    failed = sum(1 for t in tool_uses if t.is_failed)

    # Format tool names with failure markers
    tools_used = []
    for tool_use in tool_uses:
        prefix = "*" if tool_use.is_failed else ""
        tools_used.append(f"{prefix}{tool_use.tool_text}")

    # Aggregate usage across all models
    total_usage = {
        "input_tokens": 0,
        "output_tokens": 0,
        "cache_creation_input_tokens": 0,
        "cache_read_input_tokens": 0,
    }

    models_used = {}
    for model, usage in usage_by_model.items():
        # Add to totals
        for key in total_usage:
            total_usage[key] += usage[key]

        # Calculate costs for this model
        costs = calculate_costs(usage, model)

        models_used[model] = {"usage": usage.copy(), "costs": costs}

    # Calculate total costs
    total_costs = {
        "input_tokens_cost": 0.0,
        "output_tokens_cost": 0.0,
        "cache_creation_cost": 0.0,
        "cache_read_cost": 0.0,
        "total_cost": 0.0,
    }

    for model_data in models_used.values():
        for key in total_costs:
            total_costs[key] += model_data["costs"][key]

    # Round total costs
    for key in total_costs:
        total_costs[key] = round(total_costs[key], 6)

    return AgentUsage(
        agent_id=agent_id,
        subagent_type=subagent_type,
        description=description,
        is_sidechain=is_sidechain,
        messages=len(messages),
        tool_calls=len(tool_uses),
        successful_tool_calls=successful,
        failed_tool_calls=failed,
        tools_used=tools_used,
        usage=total_usage,
        costs=total_costs,
        models_used=models_used,
    )


def parse_jsonl_file(file_path: Path) -> List[Dict]:
    """
    Parse JSONL file that may contain pretty-printed JSON objects.

    Handles newline-delimited JSON where objects may span multiple lines.
    Uses a state machine to accumulate lines until a complete JSON object is formed.
    """
    entries = []
    current_lines = []
    brace_count = 0
    in_string = False
    escape_next = False

    with open(file_path) as f:
        for line in f:
            # Track if we're inside a JSON object
            for char in line:
                if escape_next:
                    escape_next = False
                    continue

                if char == '\\':
                    escape_next = True
                    continue

                if char == '"' and not escape_next:
                    in_string = not in_string
                    continue

                if not in_string:
                    if char == '{':
                        brace_count += 1
                    elif char == '}':
                        brace_count -= 1

            current_lines.append(line)

            # If brace count is zero and we have content, we have a complete object
            if brace_count == 0 and current_lines:
                json_str = ''.join(current_lines).strip()
                if json_str:
                    try:
                        obj = json.loads(json_str)
                        if isinstance(obj, dict):
                            entries.append(obj)
                    except json.JSONDecodeError as e:
                        # Silently skip malformed JSON
                        pass

                current_lines = []
                in_string = False
                escape_next = False

    return entries


def parse_main_log(log_path: Path) -> Tuple[AgentUsage, List[ToolUse], List[TaskToolCall], Dict[str, bool]]:
    """
    Parse main log file and extract:
    - Main agent usage statistics
    - List of all tool uses (for ordering)
    - List of Task tool calls
    - Map of tool_use_id -> failed status

    Returns:
        (main_agent_usage, all_tool_uses, task_tool_calls, failed_tool_map)
    """
    tool_uses = []
    task_calls = []
    failed_tool_map = {}
    usage_by_model = {}

    # Parse JSONL file
    messages = parse_jsonl_file(log_path)

    for entry in messages:
        # Process message content
        message_content = entry.get("message", {}).get("content", [])
        if not isinstance(message_content, list):
            continue

        for content_item in message_content:
            if content_item.get("type") == "tool_use":
                tool_use = extract_tool_use(content_item, entry.get("timestamp", ""))
                tool_uses.append(tool_use)

                # Check if this is a Task call
                if content_item.get("name") == "Task":
                    task_call = extract_task_call(content_item, entry.get("timestamp", ""))
                    task_calls.append(task_call)

            elif content_item.get("type") == "tool_result":
                tool_use_id = content_item.get("tool_use_id")
                is_error = content_item.get("is_error", False)
                failed_tool_map[tool_use_id] = is_error

                # Check for agent correlation
                tool_result_data = entry.get("toolUseResult", {})
                if "agentId" in tool_result_data:
                    # Find corresponding task call and set agent_id
                    for tc in task_calls:
                        if tc.tool_use_id == tool_use_id:
                            tc.agent_id = tool_result_data["agentId"]
                            break

                    # Also set agent_id on the tool_use
                    for tu in tool_uses:
                        if tu.tool_use_id == tool_use_id:
                            tu.agent_id = tool_result_data["agentId"]
                            break

        # Accumulate usage by model
        msg_usage = entry.get("message", {}).get("usage")
        model = entry.get("message", {}).get("model")
        if msg_usage and model:
            accumulate_usage(usage_by_model, model, msg_usage)

    # Mark failed tools
    for tool_use in tool_uses:
        tool_use.is_failed = failed_tool_map.get(tool_use.tool_use_id, False)

    # Build main agent usage
    main_usage = build_agent_usage(
        agent_id="main", messages=messages, tool_uses=tool_uses, usage_by_model=usage_by_model
    )

    return main_usage, tool_uses, task_calls, failed_tool_map


def parse_agent_log(log_path: Path, agent_id: str, task_call: Optional[TaskToolCall]) -> AgentUsage:
    """
    Parse agent log file and extract usage statistics.

    Args:
        log_path: Path to agent-{agent_id}.jsonl
        agent_id: Agent identifier
        task_call: TaskToolCall that created this agent (can be None for sidechain agents)

    Returns:
        AgentUsage object
    """
    tool_uses = []
    failed_tool_map = {}
    usage_by_model = {}
    is_sidechain = False

    # Parse JSONL file
    messages = parse_jsonl_file(log_path)

    for entry in messages:
        # Check sidechain flag (only need to check once)
        if "isSidechain" in entry:
            is_sidechain = entry["isSidechain"]

        # Process content (same logic as main log)
        message_content = entry.get("message", {}).get("content", [])
        if not isinstance(message_content, list):
            continue

        for content_item in message_content:
            if content_item.get("type") == "tool_use":
                tool_use = extract_tool_use(content_item, entry.get("timestamp", ""))
                tool_uses.append(tool_use)

            elif content_item.get("type") == "tool_result":
                tool_use_id = content_item.get("tool_use_id")
                is_error = content_item.get("is_error", False)
                failed_tool_map[tool_use_id] = is_error

        # Accumulate usage
        msg_usage = entry.get("message", {}).get("usage")
        model = entry.get("message", {}).get("model")
        if msg_usage and model:
            accumulate_usage(usage_by_model, model, msg_usage)

    # Mark failed tools
    for tool_use in tool_uses:
        tool_use.is_failed = failed_tool_map.get(tool_use.tool_use_id, False)

    # Build agent usage
    subagent_type = task_call.subagent_type if task_call else "unknown"
    description = task_call.description if task_call else "Sidechain agent"

    agent_usage = build_agent_usage(
        agent_id=agent_id,
        messages=messages,
        tool_uses=tool_uses,
        usage_by_model=usage_by_model,
        subagent_type=subagent_type,
        description=description,
        is_sidechain=is_sidechain,
    )

    return agent_usage


def build_ordered_tools_list(
    main_tool_uses: List[ToolUse],
    subagents: Dict[str, AgentUsage],
) -> List[str]:
    """
    Build ordered list of tool usage with proper interleaving.

    Logic:
    1. Process main agent tools in chronological order
    2. When a Task tool is encountered:
       a. Add the Task tool call itself
       b. Immediately add ALL tools from that subagent
       c. Continue with next main agent tool

    Returns:
        List of tool names, with * prefix for failed tools
    """
    result = []

    # Sort main tools by timestamp
    main_tool_uses.sort(key=lambda t: t.timestamp)

    for tool_use in main_tool_uses:
        # Format tool name with failure marker
        prefix = "*" if tool_use.is_failed else ""
        tool_text = f"{prefix}{tool_use.tool_text}"
        result.append(tool_text)

        # If this is a Task call, insert all subagent tools
        if tool_use.is_task_call and tool_use.agent_id:
            agent = subagents.get(tool_use.agent_id)
            if agent:
                result.extend(agent.tools_used)

    return result


def calculate_totals(main_agent: AgentUsage, subagents: List[AgentUsage]) -> Dict:
    """Calculate aggregate statistics across all agents."""
    total_messages = main_agent.messages
    total_tool_calls = main_agent.tool_calls
    total_successful = main_agent.successful_tool_calls
    total_failed = main_agent.failed_tool_calls

    total_usage = main_agent.usage.copy()
    total_costs = main_agent.costs.copy()

    for agent in subagents:
        total_messages += agent.messages
        total_tool_calls += agent.tool_calls
        total_successful += agent.successful_tool_calls
        total_failed += agent.failed_tool_calls

        for key in total_usage:
            total_usage[key] += agent.usage[key]

        for key in total_costs:
            total_costs[key] += agent.costs[key]

    # Round costs
    for key in total_costs:
        total_costs[key] = round(total_costs[key], 6)

    # Calculate success rate
    success_rate = total_successful / total_tool_calls if total_tool_calls > 0 else 0.0

    return {
        "total_messages": total_messages,
        "total_tool_calls": total_tool_calls,
        "total_successful_tool_calls": total_successful,
        "total_failed_tool_calls": total_failed,
        "overall_tool_success_rate": round(success_rate, 4),
        "usage": total_usage,
        "costs": total_costs,
    }


def write_usage_output(log_dir: Path, analysis: SessionAnalysis):
    """Write usage statistics to JSON file."""
    output_file = log_dir / "claude-usage-stats.json"

    # Build output structure
    output = {
        "log_file": analysis.log_file,
        "analysis_timestamp": analysis.analysis_timestamp,
        "main_agent": {
            "agent_id": analysis.main_agent.agent_id,
            "messages": analysis.main_agent.messages,
            "tool_calls": analysis.main_agent.tool_calls,
            "successful_tool_calls": analysis.main_agent.successful_tool_calls,
            "failed_tool_calls": analysis.main_agent.failed_tool_calls,
            "tool_success_rate": round(
                analysis.main_agent.successful_tool_calls / analysis.main_agent.tool_calls
                if analysis.main_agent.tool_calls > 0
                else 0.0,
                4,
            ),
            "tools_used": analysis.main_agent.tools_used,
        },
        "subagents": [
            {
                "agent_id": agent.agent_id,
                "subagent_type": agent.subagent_type,
                "description": agent.description,
                "is_sidechain": agent.is_sidechain,
                "messages": agent.messages,
                "tool_calls": agent.tool_calls,
                "successful_tool_calls": agent.successful_tool_calls,
                "failed_tool_calls": agent.failed_tool_calls,
                "tool_success_rate": round(
                    agent.successful_tool_calls / agent.tool_calls if agent.tool_calls > 0 else 0.0,
                    4,
                ),
                "tools_used": agent.tools_used,
            }
            for agent in analysis.subagents
        ],
        "totals": {
            "total_messages": analysis.totals["total_messages"],
            "total_tool_calls": analysis.totals["total_tool_calls"],
            "total_successful_tool_calls": analysis.totals["total_successful_tool_calls"],
            "total_failed_tool_calls": analysis.totals["total_failed_tool_calls"],
            "overall_tool_success_rate": analysis.totals["overall_tool_success_rate"],
        },
        "tools_used_ordered": analysis.tools_used_ordered,
    }

    with open(output_file, "w") as f:
        json.dump(output, f, indent=2)

    print(f"Usage statistics saved to: {output_file}")


def write_cost_output(log_dir: Path, analysis: SessionAnalysis):
    """Write cost statistics to JSON file."""
    output_file = log_dir / "claude-cost-stats.json"

    # Build output structure
    output = {
        "log_file": analysis.log_file,
        "analysis_timestamp": analysis.analysis_timestamp,
        "main_agent": {
            "agent_id": analysis.main_agent.agent_id,
            "usage": analysis.main_agent.usage,
            "costs": analysis.main_agent.costs,
            "by_model": {
                model: data for model, data in analysis.main_agent.models_used.items()
            },
        },
        "subagents": [
            {
                "agent_id": agent.agent_id,
                "subagent_type": agent.subagent_type,
                "description": agent.description,
                "is_sidechain": agent.is_sidechain,
                "usage": agent.usage,
                "costs": agent.costs,
                "by_model": {model: data for model, data in agent.models_used.items()},
            }
            for agent in analysis.subagents
        ],
        "totals": {
            "usage": analysis.totals["usage"],
            "costs": analysis.totals["costs"],
        },
    }

    with open(output_file, "w") as f:
        json.dump(output, f, indent=2)

    print(f"Cost statistics saved to: {output_file}")


def print_summary(analysis: SessionAnalysis, mode: str):
    """Print human-readable summary to stdout."""
    print()
    print("=" * 70)
    print("Claude Code Log Analysis Summary")
    print("=" * 70)
    print()

    if mode in ["usage", "both"]:
        print("USAGE STATISTICS:")
        print("-" * 70)
        print(f"Main Agent:")
        print(f"  Messages: {analysis.main_agent.messages}")
        print(f"  Tool calls: {analysis.main_agent.tool_calls}")
        print(f"  Successful: {analysis.main_agent.successful_tool_calls}")
        print(f"  Failed: {analysis.main_agent.failed_tool_calls}")
        success_rate = (
            analysis.main_agent.successful_tool_calls / analysis.main_agent.tool_calls
            if analysis.main_agent.tool_calls > 0
            else 0.0
        )
        print(f"  Success rate: {success_rate:.2%}")
        print()

        if analysis.subagents:
            print(f"Subagents ({len(analysis.subagents)}):")
            for agent in analysis.subagents:
                print(f"  [{agent.agent_id}] {agent.subagent_type}")
                print(f"    Description: {agent.description}")
                print(f"    Messages: {agent.messages}")
                print(f"    Tool calls: {agent.tool_calls} ({agent.successful_tool_calls} successful, {agent.failed_tool_calls} failed)")
                print()

        print(f"Totals:")
        print(f"  Total messages: {analysis.totals['total_messages']}")
        print(f"  Total tool calls: {analysis.totals['total_tool_calls']}")
        print(f"  Overall success rate: {analysis.totals['overall_tool_success_rate']:.2%}")
        print()

    if mode in ["cost", "both"]:
        print("COST STATISTICS:")
        print("-" * 70)
        print(f"Main Agent:")
        print(f"  Input tokens: {analysis.main_agent.usage['input_tokens']:,}")
        print(f"  Output tokens: {analysis.main_agent.usage['output_tokens']:,}")
        print(f"  Cache creation tokens: {analysis.main_agent.usage['cache_creation_input_tokens']:,}")
        print(f"  Cache read tokens: {analysis.main_agent.usage['cache_read_input_tokens']:,}")
        print(f"  Total cost: ${analysis.main_agent.costs['total_cost']:.4f}")
        print()

        if analysis.subagents:
            print(f"Subagents ({len(analysis.subagents)}):")
            for agent in analysis.subagents:
                print(f"  [{agent.agent_id}] {agent.subagent_type}")
                print(f"    Input tokens: {agent.usage['input_tokens']:,}")
                print(f"    Output tokens: {agent.usage['output_tokens']:,}")
                print(f"    Cache creation tokens: {agent.usage['cache_creation_input_tokens']:,}")
                print(f"    Cache read tokens: {agent.usage['cache_read_input_tokens']:,}")
                print(f"    Cost: ${agent.costs['total_cost']:.4f}")
                print()

        print(f"Total:")
        print(f"  Total input tokens: {analysis.totals['usage']['input_tokens']:,}")
        print(f"  Total output tokens: {analysis.totals['usage']['output_tokens']:,}")
        print(f"  Total cache creation tokens: {analysis.totals['usage']['cache_creation_input_tokens']:,}")
        print(f"  Total cache read tokens: {analysis.totals['usage']['cache_read_input_tokens']:,}")
        print(f"  Total cost: ${analysis.totals['costs']['total_cost']:.4f}")
        print()

    print("=" * 70)


def main():
    """
    Main execution flow:
    1. Parse command line arguments
    2. Parse main log file
    3. Discover and parse agent logs
    4. Build correlations
    5. Calculate aggregate statistics
    6. Output results
    """
    parser = argparse.ArgumentParser(
        description="Analyze Claude Code logs with subagent support",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Analyze usage and costs
  %(prog)s /path/to/session.jsonl

  # Analyze only usage
  %(prog)s /path/to/session.jsonl --mode usage

  # Analyze only costs
  %(prog)s /path/to/session.jsonl --mode cost
""",
    )
    parser.add_argument("log_file", help="Path to main log file (UUID.jsonl)")
    parser.add_argument(
        "--mode",
        choices=["usage", "cost", "both"],
        default="both",
        help="Analysis mode (default: both)",
    )
    args = parser.parse_args()

    log_file = Path(args.log_file)
    if not log_file.exists():
        print(f"Error: Log file not found: {log_file}", file=sys.stderr)
        sys.exit(1)

    log_dir = log_file.parent

    # Parse main log
    print(f"Analyzing main log: {log_file.name}")
    main_usage, main_tool_uses, task_calls, failed_map = parse_main_log(log_file)

    # Discover and parse agent logs
    agent_logs = list(log_dir.glob("agent-*.jsonl"))
    print(f"Found {len(agent_logs)} agent log files")

    subagents = {}
    subagent_list = []  # Ordered list

    for agent_log in agent_logs:
        agent_id = agent_log.stem.replace("agent-", "")

        # Find corresponding task call
        task_call = None
        for tc in task_calls:
            if tc.agent_id == agent_id:
                task_call = tc
                break

        # If no task call found, this might be a sidechain agent
        if not task_call:
            print(f"  Warning: Agent log found without Task call: {agent_id} (might be sidechain)")

        print(f"  Parsing agent: {agent_id}" + (f" ({task_call.subagent_type})" if task_call else " (orphaned)"))
        agent_usage = parse_agent_log(agent_log, agent_id, task_call)
        subagents[agent_id] = agent_usage
        subagent_list.append(agent_usage)

    # Build ordered tools list
    tools_ordered = build_ordered_tools_list(main_tool_uses, subagents)

    # Calculate totals
    totals = calculate_totals(main_usage, subagent_list)

    # Build analysis object
    analysis = SessionAnalysis(
        log_file=str(log_file),
        analysis_timestamp=datetime.utcnow().isoformat() + "Z",
        main_agent=main_usage,
        subagents=subagent_list,
        totals=totals,
        tools_used_ordered=tools_ordered,
    )

    # Write output files
    if args.mode in ["usage", "both"]:
        write_usage_output(log_dir, analysis)

    if args.mode in ["cost", "both"]:
        write_cost_output(log_dir, analysis)

    # Print summary
    print_summary(analysis, args.mode)


if __name__ == "__main__":
    main()
