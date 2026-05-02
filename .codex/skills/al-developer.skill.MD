# AKSA AI Document Processor – AL Developer Skills

## 1. Purpose

This document outlines the **required skills, knowledge, and best practices** that the AL developer (or Codex AI) must follow when implementing the AKSA AI Document Processor extension for Microsoft Dynamics 365 Business Central.

The goal is to ensure high code quality, maintainability, consistency with Business Central standards, and seamless integration with Azure AI services.

## 2. Core Technologies & Skills Required

| Area                          | Required Skills / Technologies |
|------------------------------|--------------------------------|
| **Language**                 | AL (Application Language) – Advanced level |
| **Development Environment**  | Visual Studio Code + AL Language extension |
| **Platform**                 | Microsoft Dynamics 365 Business Central (SaaS / Cloud) |
| **Document AI**              | Azure AI Document Intelligence (formerly Form Recognizer) – Read & Layout models |
| **AI Integration**           | Azure OpenAI / OpenAI service (via HTTP calls or Copilot framework) |
| **Vector Search**            | Azure AI Search (vector search / semantic search) – for large catalogue scenarios |
| **Integration Pattern**      | REST API calls, HttpClient, background tasks (Job Queue), Events & Subscribers |
| **Data Model**               | Tables, Table Extensions, Enum Extensions, Codeunits |
| **UI**                       | Pages, Page Extensions, Card & List pages, FactBoxes |
| **Security**                 | Permissions, Permission Sets, Data sensitivity |

## 3. Required AL Development Skills

- Strong proficiency in modern AL syntax (procedures, local variables, error handling with `Error()` / `TestField()`)
- Extension development model (no base object modifications)
- Event-driven programming (`[EventSubscriber]`, custom events)
- Codeunit design and reusability
- Background processing using **Job Queue** and **Task Scheduler**
- Proper error handling and user-friendly messages
- Performance optimization (avoid unnecessary database calls, use queries when possible)
- Testing (Test Codeunits, UI tests)
- ALM best practices (AppSource readiness, versioning, dependencies)

## 4. Architecture & Design Principles

- Follow the two-pattern architecture defined in `docs/Architecture.MD` (Medium vs Large catalogue)
- Use **RAG (Retrieval-Augmented Generation)** pattern for large catalogues
- Keep business logic inside Business Central as much as possible
- Treat AI suggestions as **recommendations** only — always include human review step
- Use **temporary records** and **records variables** appropriately for draft processing
- Separate concerns:
  - One codeunit for Azure AI Document Intelligence calls
  - One for Vector Search / Azure AI Search
  - One for AI prompting and response parsing
  - One for Quote creation logic

## 5. Coding Standards & Best Practices

- Follow official **AL Coding Guidelines** and **AL Guidelines.dev** recommendations
- Naming conventions:
  - Objects: `AKSA Draft Document`, `AKSA AI Document Processor`, etc.
  - Procedures: Clear, action-oriented names (`ExtractDocumentUsingAI`, `MatchItemsWithCatalogue`)
  - Variables: `local`, `var`, meaningful names
- Use `with` sparingly, prefer explicit variable usage
- Implement proper dependency injection where possible
- Use interfaces for better testability (when applicable)
- Add meaningful comments and XML documentation for public procedures
- Keep procedures short and single-responsibility

## 6. Integration Guidelines

- Use **HttpClient** with proper headers, authentication (Managed Identity or API Key), and error handling
- Implement retry logic for external service calls
- Store sensitive settings (Endpoint, Key) in **Isolated Storage** or use **Azure Key Vault** integration
- Log important steps and errors using **Session Event** or custom log table
- Support both synchronous and asynchronous (background) processing modes

## 7. Security & Compliance

- Never hardcode API keys
- Apply least-privilege permission sets
- Handle confidential document data carefully
- Ensure GDPR / data residency compliance when using Azure AI services

## 8. Deliverables Expected from Developer / Codex

- Full AL source code following the defined architecture
- Proper object naming and ID ranges
- Installation and upgrade logic (`Install.Codeunit`, `Upgrade.Codeunit`)
- Permission sets
- Setup tables and pages (if needed)
- Detailed inline comments
- Unit tests where critical

---

**Document Status:** Draft  
**Version:** 1.0  
**Last Updated:** May 2026  
**Project:** AKSA AI Document Processor
