#!/usr/bin/env python3

from pathlib import Path
import re


ROOT = Path("game/scripts/vscripts")

warning_count = 0


def warning(path: Path, line: int, message: str) -> None:
    global warning_count
    warning_count += 1

    relative = path.as_posix()

    print(
        f"::warning file={relative},line={line}::{message}"
    )


def nearest_function(lines: list[str], index: int) -> str | None:
    function_pattern = re.compile(
        r"^\s*(?:local\s+)?function\s+([A-Za-z0-9_:.]+)"
    )

    for current in range(index, -1, -1):
        match = function_pattern.search(lines[current])

        if match:
            return match.group(1)

    return None


if not ROOT.exists():
    raise SystemExit(f"Lua source directory not found: {ROOT}")


for path in sorted(ROOT.rglob("*.lua")):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    for index, line in enumerate(lines):
        line_number = index + 1

        interval = re.search(
            r"\b(?:THINK_INTERVAL|[A-Z0-9_]+_THINK_INTERVAL)"
            r"\s*=\s*([0-9]*\.?[0-9]+)",
            line,
        )

        if interval:
            value = float(interval.group(1))

            if value < 0.03:
                warning(
                    path,
                    line_number,
                    (
                        f"Very aggressive think interval ({value}s). "
                        "Verify that this frequency is necessary."
                    ),
                )

        if re.search(r"\bwhile\s+true\s+do\b", line):
            warning(
                path,
                line_number,
                "Unbounded while loop detected; verify that it cannot stall the game server.",
            )

        expensive_calls = (
            "FindUnitsInRadius(",
            "Entities:FindAll",
            "Entities:FindAllBy",
        )

        if any(call in line for call in expensive_calls):
            function_name = nearest_function(lines, index)

            if function_name and (
                "think" in function_name.lower()
                or "update" in function_name.lower()
            ):
                warning(
                    path,
                    line_number,
                    (
                        f"Potentially expensive entity scan inside "
                        f"{function_name}()."
                    ),
                )

        if "CustomNetTables:SetTableValue" in line:
            function_name = nearest_function(lines, index)

            if function_name and (
                "think" in function_name.lower()
                or "update" in function_name.lower()
            ):
                warning(
                    path,
                    line_number,
                    (
                        "Network table update inside a frequently executed "
                        f"function ({function_name})."
                    ),
                )

    if "ParticleManager:CreateParticle" in text:
        if (
            "ParticleManager:DestroyParticle" not in text
            or "ParticleManager:ReleaseParticleIndex" not in text
        ):
            create_line = next(
                (
                    index + 1
                    for index, line in enumerate(lines)
                    if "ParticleManager:CreateParticle" in line
                ),
                1,
            )

            warning(
                path,
                create_line,
                (
                    "Particle creation found without both DestroyParticle "
                    "and ReleaseParticleIndex in the same module. "
                    "Verify cleanup ownership."
                ),
            )

print()
print(f"Dota performance advisory completed with {warning_count} warning(s).")
print("Warnings are advisory and do not fail the build.")
