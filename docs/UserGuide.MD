# User Guide

- **Application:** AKSA AI Document Processor
- **Version:** 24.0.0.0

## Overview

AKSA AI Document Processor helps Microsoft Dynamics 365 Business Central users convert incoming customer requests into draft quote lines with AI-assisted item matching.

The current version integrates with OpenAI. Future versions are planned to include Azure OpenAI integration.

## Before You Start

1. Open the **AKSA Open AI Setup** page.
2. Configure the connection settings used for communication between Business Central and OpenAI.
3. Confirm that the item catalogue settings are ready for the prompt workflow.

## Configure AI Prompt Templates

Open the **AKSA AI Prompt Templates** page to create a new template or modify an existing one from the template card.

An AI prompt template defines the communication workflow sent to the AI service. In the default workflow, the app can:

1. Provide instructions to the AI service.
2. Send product catalogue information from Business Central.
3. Include data imported from the incoming document.
4. Ask the AI service how the document should be processed.

### Template Step Types

| Step type | Description |
| --- | --- |
| **Prompt** | Text instructions sent to the AI service. |
| **Item Catalogue** | A non-configurable action that provides required item catalogue data from Business Central. |
| **Document Data** | Imported document data from the related **AKSA Draft Document** record. |

You can use the default configuration, adjust prompt text, add or remove workflow steps, or create your own workflow based on business requirements.

## Process a Draft Document

### 1. Create a Draft Document

Open the **AKSA Draft Document List** page and select **New** to create a new draft document.

### 2. Complete the Header Fields

Fill in the required fields on the document card.

| Field | Description |
| --- | --- |
| **Document No.** | Number for the new document. This is generated automatically. |
| **Contact Name** | Customer, vendor, or contact name entered by the user. |
| **Type** | Quote type to create. Available values are **Sales**, **Purchase**, and **Service**. |
| **AI Prompt Template No.** | Code of the AI prompt template used for document processing. |
| **Excel Desc. Column No.** | Optional Excel column number that contains item descriptions. Providing this improves AI response quality. |
| **Excel Quantity Column No.** | Optional Excel column number that contains requested item quantities. Providing this improves AI response quality. |

### 3. Import Data From Excel

After completing the header fields, select **Import From Excel**.

The app converts the selected Excel file into a structured format and stores it in the **Document Data** field. You can review the imported structure by opening the related document data action.

### 4. Review Excel Format Guidance

The app includes an example Excel file with a customer request, but the import format is flexible.

If you do not specify the description or quantity columns, define those details in the AI prompt request. For example, the prompt can instruct the AI service to recognize only lines with a quantity greater than `0`.

### 5. Process the Document With AI

When the document data is ready, select **Process with AI**.

The OpenAI response is saved in the **AI Response** field. You can review this response to analyze the request and refine your prompts. If the document structure is recognized correctly, the draft document lines are populated with suggested items.

> **Important:** Review every suggested item before creating a quote. OpenAI provides suggestions based on the document data, item catalogue data, and prompt instructions, but the user is responsible for verifying the final result. The original item description is stored in **Description**, and the incoming document line description is stored in **Input Description**.

### 6. Review Item Suggestions

For some lines, the system may return multiple item suggestions.

To review them, select the item number on the line and then choose the **...** button. A list of suggested items appears.

### 7. Override the Item Selection

If the suggested items do not meet the customer's expectations, select the correct item directly from the item catalogue.

After selecting the item, choose the flag button. This selection is included in the next document processing cycle so the AI workflow can improve future suggestions for similar cases.

### 8. Create the Quote

Select **Evaluate to Quote** to create the final quote document.

The created quote depends on the document **Type**:

| Type | Created document |
| --- | --- |
| **Sales** | Sales Quote |
| **Purchase** | Purchase Quote |
| **Service** | Service Quote |

## Current Project Status

The application works well for the demonstrated presentation workflow, but it is not yet ready to be marketed as a broad commercial product. One customer has agreed to test it in their environment.

Features currently in progress:

- Azure OpenAI integration.
- Enhanced communication patterns with AI.
- Recognition of incoming document information from formats beyond Excel, including JPEG, JPG, and PNG.
- Improved AI suggestion logic based on previous user selections for specific communication patterns.
- Testing with real data across practical business scenarios.
