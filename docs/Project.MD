# AKSA AI Document Processor
## Project Overview

## Problem Statement

Quote creation is slow and error-prone when customers send requests with many free-text line items. Users must read the incoming document, understand each requested item, search the Business Central item catalogue, choose the best match, and manually build a quote.

AKSA AI Document Processor reduces that manual workload while keeping final control with the user.

## Project Goal

The goal is to provide an AI-assisted, human-reviewed document-to-quote workflow inside Microsoft Dynamics 365 Business Central.

The app is designed to:

- Extract incoming request data from Excel files, PDFs, and images.
- Match request lines against the item catalogue.
- Scale from medium catalogues to large catalogues through vector retrieval.
- Create draft lines that users can review and correct.
- Require approval before any official quote is created.
- Create standard Sales, Purchase, and Service Quotes in Business Central.
- Log external AI, OCR, and search communication for audit and troubleshooting.

## Implemented Solution

The current extension implements a draft-document workflow:

1. A user creates an **AKSA Draft Document**.
2. The user selects quote type and account:
   - Sales: `Customer No.`
   - Purchase: `Vendor No.`
   - Service: `Customer No.`
3. Source document data is added by:
   - **Import From Excel**, or
   - **Extract Document Data** through Azure AI Document Intelligence.
4. The user selects **Process with AI**.
5. The app builds a prompt from the active AI prompt template.
6. The app chooses the catalogue pattern:
   - Full item catalogue for medium catalogues.
   - Azure AI Search vector retrieval for large catalogues.
7. The AI response is parsed into draft lines and suggested item candidates.
8. The user reviews each line, selects or corrects the item, confirms quantity, and marks the line as reviewed.
9. The user approves the draft.
10. The user creates a standard Business Central quote.

## Key Components

| Component | Current behavior |
| --- | --- |
| Draft document | Stores source data, AI response, line suggestions, review status, account selection, and created quote number. |
| Azure AI Document Intelligence | Extracts document data from uploaded PDFs and images, including asynchronous polling. |
| AI prompt processing | Sends composed prompts to an OpenAI-compatible chat completion endpoint. |
| Medium catalogue processing | Sends the full Business Central item catalogue in the prompt. |
| Large catalogue processing | Uses embeddings and Azure AI Search vector queries to retrieve relevant item candidates. |
| Human review | Requires every line to be reviewed before approval. |
| Quote creation | Creates Sales, Purchase, or Service Quotes only from approved drafts. |
| Communication log | Stores request and response bodies and HTTP status codes for AI, OCR, and search integrations. |
| Install/default data | Creates setup defaults and a default prompt template. |
| Permissions | Provides the assignable `AKSA AI DOC PROCESS` permission set. |

## Business Value

- Reduces time spent reading and matching request lines.
- Improves consistency by using current Business Central item data.
- Keeps official quote generation inside Business Central.
- Preserves user control through explicit review and approval.
- Supports larger item catalogues without sending the full catalogue to the AI model.
- Provides auditability for external service communication.

## Current Functional Scope

Implemented:

- Excel request import.
- PDF/image extraction through Azure AI Document Intelligence.
- Prompt template based AI processing.
- Medium and large catalogue processing patterns.
- Item embedding storage and Azure AI Search catalogue upload.
- Suggested item candidates per draft line.
- Review and approval status workflow.
- Sales, Purchase, and Service Quote creation.
- Default setup and prompt template seeding.
- Communication log page.
- Permission set.

Out of scope for the current implementation:

- Automatic account identification from source document content.
- Automatic quote release, posting, or sending.
- Background processing through Job Queue.
- Managed Identity or Azure Key Vault secret retrieval.
- Automated regression test suite.
- Full learning loop from historical user corrections.

## Operational Dependencies

The following services must be configured before all features can run:

- OpenAI-compatible chat completion endpoint.
- OpenAI-compatible embedding endpoint.
- Azure AI Document Intelligence analyze endpoint.
- Azure AI Search service and index.
- Business Central item catalogue.
- Item embeddings uploaded to Azure AI Search for large catalogue processing.

## Build Status

The project builds locally with the Business Central AL compiler and checked-in symbol packages. The generated app package is written to:

```text
.snapshots\AKSA_AI_Document_Processor_compile.app
```
