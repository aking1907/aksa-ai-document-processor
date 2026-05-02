# AKSA AI Document Processor (v. 27.0.0.0)

AI-assisted document-to-quote automation for Microsoft Dynamics 365 Business Central.

AKSA AI Document Processor helps users extract request data from Excel files, PDFs, and images, match requested lines against the Business Central item catalogue, review AI suggestions, and create Sales, Purchase, or Service Quotes only after human approval.

## Current Implementation

- Draft document workspace with header fields, extracted document data, AI response storage, suggested lines, and suggested item candidates.
- Azure AI Document Intelligence integration for PDF/image extraction, including polling for asynchronous analysis results.
- OpenAI-compatible chat completion integration for prompt-based line interpretation and item matching.
- Two catalogue processing patterns:
  - Medium catalogue: sends the full Business Central item catalogue to the AI prompt.
  - Large catalogue: creates a document embedding and retrieves relevant items from Azure AI Search using vector search.
- Human-in-the-loop review: every line must have an item, positive quantity, and `Reviewed = true` before approval.
- Quote creation from approved drafts:
  - Sales Quote from `Customer No.`
  - Purchase Quote from `Vendor No.`
  - Service Quote from `Customer No.`
- AI/OCR/Search communication logging.
- Default setup and prompt template seeding on install.
- Assignable permission set: `AKSA AI DOC PROCESS`.

## Main Business Central Pages

| Page | Purpose |
| --- | --- |
| **AKSA Open AI Setup** | Configure chat, embedding, Document Intelligence, Azure AI Search, and catalogue threshold settings. |
| **AKSA Draft Document List** | Create and open draft documents. |
| **AKSA Draft Document** | Import/extract document data, process with AI, review lines, approve, and create quotes. |
| **AKSA AI Prompt Templates** | Maintain prompt templates and active prompt steps. |
| **AKSA AI Communication Log** | Review logged request and response bodies for AI, OCR, and search calls. |
| **Item List** | Update item embeddings and inspect stored embedding data through AKSA actions. |

## Build

The project builds with the AL compiler from the Business Central VS Code extension and the checked-in symbol packages:

```powershell
alc.exe /project:"C:\Programming\AKSA\GitHub\AIDocumentProcessor" /packagecachepath:"C:\Programming\AKSA\GitHub\AIDocumentProcessor\.alpackages" /out:"C:\Programming\AKSA\GitHub\AIDocumentProcessor\.snapshots\AKSA_AI_Document_Processor_compile.app"
```

The latest local build artifact is written to:

```text
.snapshots\AKSA_AI_Document_Processor_compile.app
```

## Documentation

- [Architecture](docs/Architecture.MD)
- [Project Overview](docs/Project.MD)
- [User Guide](docs/UserGuide.MD)

## Notes

External AI services must be configured before OCR, chat completion, embeddings, or vector search can run. AI output is treated as a recommendation only; the user remains responsible for validating each line before quote creation.
