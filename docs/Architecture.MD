# AKSA AI Document Processor  
## System Architecture

### 1. Introduction

The **AKSA AI Document Processor** is an intelligent document automation solution integrated with Microsoft Dynamics 365 Business Central. It accelerates the creation of Sales, Purchase, and Service Quotes by automatically extracting data from uploaded documents (PDFs, images, scans) and intelligently matching line items to the company's item catalogue.

The architecture is designed to handle catalogues of varying sizes while maintaining a consistent user experience and ensuring human oversight remains central to the process.

### 2. Overview

AKSA AI Document Processor supports two scalable processing patterns based on the size of the item catalogue in Business Central:

- **Medium catalogue** (< ~1,000 items): The full catalogue is included directly in the AI prompt.
- **Large catalogue** (> ~1,000 items): The catalogue is indexed in a vector search store. Only the most relevant items are retrieved via similarity search and sent to the AI model.

This hybrid approach ensures optimal performance, cost-efficiency, and context quality regardless of catalogue size.

### 3. Core Components

| Component                    | Responsibility |
|-----------------------------|--------------|
| **Business Central**        | Hosts draft documents, item catalogue, prompt templates, business logic, and final quote creation. |
| **AKSA Draft Document**     | Intermediate entity that stores the uploaded document, extracted data, AI suggestions, and user corrections. |
| **Azure AI Document Intelligence** | Performs high-accuracy OCR and layout analysis to extract structured text, tables, and document elements. |
| **AI Model**                | Interprets extracted document data, applies business-specific instructions, and suggests matching catalogue items. Can be powered by Azure OpenAI, OpenAI, or compatible models. |
| **Vector Search Store**     | Indexes item catalogue embeddings for efficient semantic retrieval (recommended: Azure AI Search with vector capabilities). |
| **Quote Documents**         | Final Sales Quote, Purchase Quote, or Service Quote generated in Business Central after review. |

### 4. Processing Patterns

#### Pattern 1: Medium Item Catalogue (< ~1,000 items)

In this pattern, the entire item catalogue fits comfortably within the AI model's context window.

**Workflow:**

1. User creates an **AKSA Draft Document** in Business Central.
2. User uploads the source document (PDF, image, or scan).
3. The document is sent to **Azure AI Document Intelligence** for OCR and structural extraction.
4. Business Central retrieves the full item catalogue from the ERP database.
5. The extracted document data, complete catalogue, and prompt instructions are sent to the AI model.
6. The AI model returns suggested item matches and structured document lines.
7. Suggestions are populated into the AKSA Draft Document.
8. User reviews, corrects, and approves the lines.
9. The draft is converted into a standard Sales, Purchase, or Service Quote in Business Central.

#### Pattern 2: Large Item Catalogue (> ~1,000 items)

When the catalogue is too large to send in full, a retrieval-augmented approach is used.

**Workflow:**

1. User creates an **AKSA Draft Document** in Business Central.
2. User uploads the source document.
3. The document is processed by **Azure AI Document Intelligence** for OCR and layout analysis.
4. The system queries the **vector search store** to retrieve the most semantically relevant catalogue items.
5. Business Central sends the extracted document data, the retrieved item subset, and prompt instructions to the AI model.
6. The AI model returns suggested matches and document lines.
7. Suggestions are populated into the AKSA Draft Document.
8. User reviews and makes necessary corrections.
9. The approved draft is converted into a final Quote in Business Central.

### 5. Scaling Strategy

The architecture gracefully scales by switching between the two patterns:

- **Medium pattern** offers simplicity and lower latency.
- **Large pattern** maintains high relevance and avoids context overflow by using vector-based retrieval (RAG-style).

Both patterns deliver the **same user experience**:
- Users always work within the familiar **AKSA Draft Document** page.
- AI suggestions are treated as recommendations only.
- Full human review and approval occur before quote creation.
- All business logic and final document generation stay inside Business Central.

### 6. Human Review & Governance

AI-generated suggestions are **recommendations**, not automated decisions. Users are fully responsible for reviewing matches, correcting errors, and approving the draft document before it is converted into an official quote. This human-in-the-loop approach ensures accuracy and compliance with business rules.

### 7. Key Benefits

- Consistent and intuitive user experience across catalogue sizes
- High-quality OCR powered by Azure AI Document Intelligence
- Cost-efficient and context-aware AI processing
- Full integration with Business Central (no data leaves the ERP unnecessarily)
- Scalable from small to very large item catalogues
- Strong auditability and user accountability

---

**Document Status:** Draft  
**Version:** 27.0.0.1 
**Date:** May 2026
