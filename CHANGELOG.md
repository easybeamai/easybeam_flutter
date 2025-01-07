## 2.0.0

Breaking Changes:

- Renamed Workflows to Agents:
  - `streamWorkflow()` -> `streamAgent()`
  - `getWorkflow()` -> `getAgent()`
  - `workflowId` parameter -> `agentId`
- Renamed Portals to Prompts:
  - `streamPortal()` -> `streamPrompt()`
  - `getPortal()` -> `getPrompt()`
  - `portalId` parameter -> `promptId`
- Renamed `PortalResponse` to `ChatResponse` for better clarity

## 1.0.0

Initial release

- Streaming Workflows & Portals
- Getting Workflows & Portals
- Reviewing
