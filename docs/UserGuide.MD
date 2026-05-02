# AKSA AI Document Processor
## User Guide

- **Application:** AKSA AI Document Processor
- **Version:** 27.0.0.0
- **Platform:** Microsoft Dynamics 365 Business Central

## Overview

AKSA AI Document Processor helps users convert incoming request documents into reviewed quote drafts. The app can import data from Excel, extract data from PDFs and images, use AI to suggest matching items, and create Sales, Purchase, or Service Quotes after user approval.

AI results are suggestions. Users must review and approve the draft before a quote can be created.

## Before You Start

Open **AKSA Open AI Setup** and configure the required external services.

### AI Model

| Field | Description |
| --- | --- |
| **Open AI Model URL** | Endpoint used to retrieve available models. |
| **Open AI URL** | Chat completion endpoint used by **Process with AI**. |
| **Open AI Model** | Model sent in chat completion requests. |
| **Open AI Key** | API key used for chat completion. Also used for embeddings when no embedding key is configured. |

### Document Intelligence

| Field | Description |
| --- | --- |
| **Document Intelligence URL** | Azure AI Document Intelligence analyze endpoint used for uploaded PDFs/images. |
| **Document Intelligence Key** | Subscription key sent with OCR requests. |

### Item Catalogue

| Field | Description |
| --- | --- |
| **Default Prompt Template No.** | Default prompt template assigned to new draft documents. Seeded as `DEFAULT`. |
| **Catalogue Size Threshold** | Item count threshold used to switch between full catalogue prompting and vector retrieval. Defaults to `1000`. |
| **Item Catalogue Batch Size** | Optional batch size for catalogue export helpers. |

### Vector Search

| Field | Description |
| --- | --- |
| **Azure AI Search URL** | Azure AI Search service URL. |
| **Azure AI Search Index Name** | Search index that stores item catalogue documents. |
| **Azure AI Search Api Version** | Azure AI Search REST API version. Defaults to `2024-07-01`. |
| **Azure AI Search Key** | Azure AI Search API key. |
| **Vector Result Count** | Number of relevant catalogue items retrieved for large catalogue processing. Defaults to `25`. |

### Embeddings

| Field | Description |
| --- | --- |
| **Open AI Embedding URL** | Endpoint used to create item and document embeddings. |
| **Open AI Embedding Model** | Embedding model name when required by the endpoint. |
| **Open AI Embedding Key** | Optional embedding API key. If blank, **Open AI Key** is used. |

## Default Prompt Template

The app seeds a default template named `DEFAULT`. It contains three active steps:

| Step type | Purpose |
| --- | --- |
| **Prompt** | Gives the AI matching instructions and required JSON response format. |
| **Item Catalogue** | Inserts either the full item catalogue or the vector-retrieved item subset. |
| **Document Data** | Inserts imported or extracted source document data. |

Use **AKSA AI Prompt Templates** to review or adjust prompt text. The AI response should contain a `data` array with descriptions, quantities, and suggested item numbers.

## Prepare Item Embeddings for Large Catalogues

Large catalogue processing requires item embeddings and an Azure AI Search index.

1. Open **Item List**.
2. Filter or select the items to index.
3. Choose **AKSA Update Embedding by Filter** to create embeddings on the selected Item records.
4. Open **AKSA Open AI Setup**.
5. Choose **Upload Item Catalogue** to upload item catalogue documents to Azure AI Search.

The upload includes item number, description, base unit of measure, and stored embedding vector when available.

## Process a Draft Document

### 1. Create a Draft

Open **AKSA Draft Document List** and create a new draft.

New drafts receive the default prompt template when no prompt template is selected.

### 2. Complete Header Fields

| Field | Required | Description |
| --- | --- | --- |
| **Document No.** | Yes | Draft document number. |
| **Type** | Yes | Quote type: Sales, Purchase, or Service. |
| **Customer No.** | Sales and Service | Customer used when creating Sales or Service Quotes. |
| **Vendor No.** | Purchase | Vendor used when creating Purchase Quotes. |
| **Contact Name** | No | Filled from customer/vendor when selected, or entered manually for reference. |
| **AI Prompt Template No.** | Yes | Prompt template used for AI processing. |
| **Excel Desc. Column No.** | Optional | Excel column number containing item descriptions. |
| **Excel Quantity Column No.** | Optional | Excel column number containing quantities. |

### 3. Add Document Data

You can add document data in either of two ways.

#### Import from Excel

1. Choose **Import From Excel**.
2. Select an `.xlsx` file.
3. Select the worksheet.
4. The app converts worksheet data to JSON and stores it in **Document Data**.

If description and quantity column numbers are provided on the draft, the import creates normalized `dsc` and `qty` values. Otherwise, the app stores the available worksheet fields and the prompt must explain how to interpret them.

#### Extract from PDF or Image

1. Choose **Extract Document Data**.
2. Upload a PDF, PNG, JPG, or JPEG file.
3. The app sends the file to Azure AI Document Intelligence.
4. If Azure returns an asynchronous operation, the app polls until the result succeeds, fails, or times out.
5. The extraction response is stored in **Document Data**.
6. The uploaded file name is stored in **Source File Name**.

### 4. Process with AI

Choose **Process with AI**.

The app:

1. Validates that document data and a prompt template exist.
2. Counts Business Central items.
3. Uses the medium catalogue pattern when the item count is at or below the threshold.
4. Uses the large catalogue pattern when the item count is above the threshold.
5. Sends the composed prompt to the configured chat endpoint.
6. Stores the raw response in **AI Response**.
7. Creates draft lines and suggested item candidates.
8. Sets the draft status to **AI Suggested**.

### 5. Review Suggested Lines

Review every line in the draft subform.

For each line:

1. Check **Input Description**.
2. Confirm or change **Item No.**.
3. Confirm **Quantity**.
4. Use the assist action on **Item No.** to choose from AI suggested item candidates when available.
5. Set **Reviewed** to true when the line is correct.

Changing the item or quantity resets **Reviewed** to false.

### 6. Approve the Draft

Choose **Approve Draft** after all lines are reviewed.

Approval requires:

- Required customer or vendor account on the header.
- At least one draft line.
- Item number on every line.
- Quantity greater than zero on every line.
- **Reviewed** checked on every line.

After approval, the draft status becomes **Approved** and the app records **Approved By** and **Approved At**.

### 7. Create the Quote

Choose **Create Quote**.

The app creates a standard Business Central quote based on draft type:

| Draft Type | Required account | Created document |
| --- | --- | --- |
| Sales | Customer No. | Sales Quote |
| Purchase | Vendor No. | Purchase Quote |
| Service | Customer No. | Service Quote |

After quote creation:

- **Quote No.** is stored on the draft.
- Status becomes **Converted**.
- The converted draft cannot be changed or reprocessed.

## Review Communication Logs

Open **AKSA AI Communication Log** to review integration calls.

The log includes:

- Type: AI, OCR, or Search.
- Description of the step.
- HTTP status code.
- Created date/time.
- Request body blob.
- Response body blob.

Use this page for troubleshooting prompts, service responses, and Azure AI Search requests.

## Status Reference

| Status | Meaning |
| --- | --- |
| Open | Draft is being prepared or corrected. |
| AI Suggested | AI has populated draft lines and suggestions. |
| Approved | User has reviewed all lines and approved quote creation. |
| Converted | Quote has been created and the draft is locked. |

## Common Errors

| Message | What to check |
| --- | --- |
| **Document Data is empty.** | Import from Excel or extract document data before processing with AI. |
| **AI Prompt Template lines were not found.** | Confirm the selected prompt template has active lines. |
| **Line must be reviewed before the draft can be approved.** | Mark every corrected line as Reviewed. |
| **Customer No. must have a value.** | Sales and Service drafts require a customer. |
| **Vendor No. must have a value.** | Purchase drafts require a vendor. |
| **Document Intelligence accepted the document but did not return an Operation-Location header.** | Confirm the configured Document Intelligence endpoint supports asynchronous analyze operations. |
| **Azure AI Search response does not contain a value array.** | Confirm the Azure AI Search endpoint, index name, API version, and request permissions. |

## Permissions

Assign users the **AKSA AI DOC PROCESS** permission set so they can access the extension tables, pages, reports, and codeunits.
