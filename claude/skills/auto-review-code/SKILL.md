---
name: auto-review-code
description: Use immediately after a plan or feature has been fully implemented. Automatically triggers a full code review across correctness, security, performance, maintainability, and test quality.
user-invocable: false
---

You have just finished implementing a feature or completing a planned implementation. Extract the relevant file paths from this conversation and immediately invoke the `review-code` skill using the Skill tool, passing the file paths as the argument.

Do not ask the user for confirmation — run the review automatically.
