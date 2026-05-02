# AKSA AI Document Processor
## System Architecture

## 1. Purpose

AKSA AI Document Processor is a Microsoft Dynamics 365 Business Central extension that turns incoming request documents into reviewed draft quote lines and then into standard Business Central quote documents.

The extension keeps the business workflow inside Business Central:

1. A user creates an **AKSA Draft Document**.
2. Request data is imported from Excel or extracted from a PDF/image through Azure AI Document Intelligence.
3. The app builds an AI prompt using active prompt template lines.
4. The app supplies catalogue context using either the full item catalogue or a vector-search result set.
5. AI suggestions populate draft lines and suggested item candidates.
6. A user reviews every line and approves the draft.
7. The app creates a Sales, Purchase, or Service Quote.

AI suggestions are never treated as automatic decisions. Quote creation is blocked until the user explicitly reviews and approves the draft.

## 2. Core Components

| Component | AL object(s) | Responsibility |
| --- | --- | --- |
| Draft document | `AKSA Draft Document Header`, `AKSA Draft Document Line`, `AKSA Draft Doc. Line Item` | Stores source data, AI response, processing pattern, review status, suggested lines, and suggested items. |
| Draft document UI | `AKSA Draft Document`, `AKSA Draft Document Subform`, `AKSA Draft Document List`, `AKSA Draft Doc. Line Items` | Provides import, extraction, AI processing, line review, approval, and quote creation actions. |
| AI setup | `AKSA Open AI Setup`, `AKSA Open AI Setup` page | Stores chat, embedding, Document Intelligence, Azure AI Search, catalogue threshold, and default prompt settings. |
| Prompt templates | `AKSA AI Prompt Template Header`, `AKSA AI Prompt Template Line` | Defines the ordered prompt sections sent to the AI model. |
| Document extraction | `AKSA Azure Doc Intelligence` | Uploads PDF/image streams to Azure AI Document Intelligence and polls `Operation-Location` when the service returns `202 Accepted`. |
| Prompt orchestration | `AKSA AI Document Processor` | Validates the draft, builds the prompt, chooses medium or large catalogue processing, parses AI JSON, and creates draft lines. |
| Chat integration | `AKSA Open AI Management` | Sends OpenAI-compatible chat completion requests and parses the first returned message content. |
| Item catalogue | `AKSA Item Catalogue Mgt.`, `AKSA Item` table extension | Exports item catalogue JSON and stores item embedding data on Item records. |
| Vector search | `AKSA Vector Search Mgt.` | Creates embeddings, uploads indexed item data, and retrieves relevant catalogue items from Azure AI Search. |
| Quote creation | `AKSA Quote Mgt.` | Creates Sales, Purchase, or Service Quotes from approved drafts. |
| Audit logging | `AKSA AI Communication Log Mgt.`, `AKSA AI Communication Log` page | Logs AI, OCR, and search request/response payloads and HTTP status codes. |
| Install and permissions | `AKSA Install`, `AKSA Default Data Mgt.`, `AKSA AI DOC PROCESS` | Seeds default setup/prompt data and grants extension object access. |

## 3. Draft Document Data Model

The draft header stores:

- Document number and quote type: Sales, Purchase, or Service.
- `Customer No.` for Sales and Service Quotes.
- `Vendor No.` for Purchase Quotes.
- Imported or extracted `Document Data`.
- Raw `AI Response`.
- Uploaded `Source File Name`.
- Selected `Processing Pattern`.
- Review `Status`: Open, AI Suggested, Approved, Converted.
- Approval audit fields: `Approved By`, `Approved At`.
- Created `Quote No.` after conversion.
- AI prompt template number.

The draft line stores:

- Incoming line description.
- Selected item number and item description.
- Quantity.
- `Reviewed` flag.

Suggested item candidates are stored separately in `AKSA Draft Doc. Line Item` and can be selected from the draft line item assist action.

## 4. Processing Patterns

The app supports two catalogue patterns. The threshold is configured in **AKSA Open AI Setup** with `Catalogue Size Threshold` and defaults to `1000`.

### Pattern 1: Medium Catalogue

Used when the Business Central item count is less than or equal to the configured threshold.

Workflow:

1. `AKSA AI Document Processor` reads the full item catalogue through `AKSA Item Catalogue Mgt.`.
2. The catalogue is serialized as JSON with item number, description, base unit of measure, and inventory.
3. The full catalogue is inserted into the prompt template section of type **Item Catalogue**.
4. The processing pattern is stored as `Medium catalogue`.

### Pattern 2: Large Catalogue

Used when the item count is greater than the configured threshold.

Workflow:

1. The source document data is sent to the configured embedding endpoint.
2. `AKSA Vector Search Mgt.` sends an Azure AI Search request with `vectorQueries`.
3. The query searches the configured vector field `dsc_v`.
4. Only the returned item subset is converted to catalogue JSON.
5. That subset is inserted into the prompt template section of type **Item Catalogue**.
6. The processing pattern is stored as `Large catalogue`.

Azure AI Search upload expects item documents with these fields:

| Field | Purpose |
| --- | --- |
| `no` | Business Central item number. |
| `dsc` | Item description. |
| `uom` | Base unit of measure. |
| `dsc_v` | Stored embedding vector for item description search. |

## 5. External Service Integration

### Chat Completion

`AKSA Open AI Management` sends a JSON chat completion request to `Open AI URL` with:

- `model` from `Open AI Model`
- one user message containing the composed prompt
- `temperature = 0.2`
- `max_tokens = 4000`

Authentication uses the configured `Open AI Key` as a bearer token.

### Embeddings

`AKSA Vector Search Mgt.` sends embedding requests to `Open AI Embedding URL`.

- `Open AI Embedding Model` is included when configured.
- `Open AI Embedding Key` is used when provided.
- If the embedding key is blank, the app falls back to `Open AI Key`.

### Azure AI Search

`AKSA Vector Search Mgt.` uses:

- `Azure AI Search URL`
- `Azure AI Search Key`
- `Azure AI Search Index Name`
- `Azure AI Search Api Version`, default `2024-07-01`
- `Vector Result Count`, default `25`

### Azure AI Document Intelligence

`AKSA Azure Doc Intelligence` uploads the selected document stream to `Document Intelligence URL` with the `Document Intelligence Key`.

If the service returns `202 Accepted`, the code reads the `Operation-Location` response header and polls the result endpoint until:

- `status = succeeded`, then the response is saved as document data.
- `status = failed`, then processing stops with an error.
- 30 polling attempts pass, then processing stops with a timeout error.

## 6. Prompt and Response Contract

Default data is seeded by `AKSA Default Data Mgt.`. The default prompt template number is `DEFAULT`.

The default template contains:

1. **Prompt** - instructions for item matching and JSON response format.
2. **Item Catalogue** - dynamic catalogue context from either medium or large processing.
3. **Document Data** - imported or extracted source data.

The expected AI response shape is:

```json
{
  "data": [
    {
      "dsc": "source line description",
      "qty": 1,
      "items": [
        {
          "no": "ITEMNO"
        }
      ]
    }
  ]
}
```

The parser also accepts `description`, `quantity`, `no`, and `itemNo` aliases where implemented.

## 7. Human Review and Governance

The draft status controls the workflow:

| Status | Meaning |
| --- | --- |
| Open | Draft is being prepared or corrected. |
| AI Suggested | AI processing has populated suggested lines. |
| Approved | Every line has been reviewed and the draft is ready for quote creation. |
| Converted | A quote has been created and the draft is locked from further changes. |

Approval requires:

- Header account selected:
  - `Customer No.` for Sales and Service.
  - `Vendor No.` for Purchase.
- At least one draft line.
- Every line has an `Item No.`.
- Every line has `Quantity > 0`.
- Every line has `Reviewed = true`.

Changing a line item or quantity resets the line review flag. Changing approved draft lines reopens the draft to `AI Suggested`. Converted drafts cannot be changed or reprocessed.

## 8. Quote Creation

`AKSA Quote Mgt.` creates standard Business Central quote records:

| Draft type | Required account | Created document |
| --- | --- | --- |
| Sales | `Customer No.` | Sales Quote |
| Purchase | `Vendor No.` | Purchase Quote |
| Service | `Customer No.` | Service Quote |

Quote line creation follows standard Business Central validation patterns:

1. Create the header.
2. Assign the customer or vendor.
3. Insert each quote line.
4. Validate item and quantity.
5. Store the quote number on the draft and mark the draft as Converted.

## 9. Security, Audit, and Permissions

- API keys are setup fields and masked on the setup page.
- Integration request and response payloads are logged in `AKSA Open AI Communication Log`.
- The log page allows users to inspect request and response body blobs.
- The assignable permission set `AKSA AI DOC PROCESS` grants access to extension objects.
- The app keeps the official quote creation logic inside Business Central.

## 10. Current Scope and Limitations

Implemented:

- Excel import to JSON document data.
- PDF/image upload to Azure AI Document Intelligence.
- OpenAI-compatible chat prompt processing.
- Item catalogue JSON generation.
- Item embeddings stored on Item records.
- Azure AI Search upload and vector retrieval.
- Human review and approval workflow.
- Sales, Purchase, and Service Quote creation.
- Setup and default prompt seeding.
- Communication logging.

Not currently implemented:

- Automatic customer/vendor recognition from source documents.
- Automatic quote sending to customers or vendors.
- Background Job Queue processing.
- Managed Identity or Key Vault based secret storage.
- Automated test codeunits.
- Learning from user corrections beyond storing reviewed draft decisions in Business Central data.

---

**Document Status:** Current implementation reference
**Version:** 27.0.0.0
**Date:** May 2026
