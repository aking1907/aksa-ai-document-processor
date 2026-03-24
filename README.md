# Presentation of the Application: AKSA AI Document Processor

**Solution Architect:** Andrii Korol  

---

## Problem Statement
In today’s fast-paced business environment, companies often face significant challenges when generating quotes for customer requests. This process becomes particularly cumbersome when dealing with large requests that contain numerous line items. For instance, imagine a customer submits a request with around 100 different items. 

**The current workflow typically involves the following steps:**
* **Understanding the Request:** Employees need to carefully read and interpret the item descriptions provided by the customer.
* **Searching the Database:** They then have to manually search their internal database to find matching items.
* **Generating the Quote:** Finally, they compile the information and create a detailed quote for the customer.

This manual process is time-consuming and prone to errors, leading to delays and potential inaccuracies in the quotes provided. As a result, companies may experience reduced customer satisfaction and lost business opportunities.

---

## Project
To address the inefficiencies in generating quotes based on customer requirements, we propose the implementation of an automated quoting system. This system leverages advanced technologies to streamline the process and reduce the time and effort required.

### Key Components:
* **Natural Language Processing (NLP):**
    * **Understanding Customer Requests:** Utilize NLP algorithms to automatically interpret and categorize item descriptions.
    * **Contextual Analysis:** Ensure accurate understanding of the specifics of each item to match them correctly with database entries.
* **Database Integration:**
    * **Automated Search:** Integrate with the company’s product database (ERP) for automatic matching.
    * **Real-Time Updates:** Ensure the system uses the latest product information.
* **Machine Learning (ML):**
    * **Predictive Matching:** Implement models to predict the best matches based on historical data.
    * **Continuous Improvement:** Use feedback loops to improve accuracy over time.
* **User-Friendly Interface:**
    * **Simplified Workflow:** An intuitive interface that reduces the need for extensive training.
    * **Customization Options:** Easy adjustments to meet specific customer needs.
* **Efficiency and Accuracy:**
    * **Time Savings:** Allows employees to focus on higher-value tasks.
    * **Error Reduction:** Minimizes human errors for more reliable quotes.

---

## Proposed Solution
We have developed an application built on the **Microsoft Dynamics 365 Business Central ERP system**. This application integrates AI technologies to enable users to automatically generate sales quotes using product catalog data directly from their ERP.

### Workflow Process Plan
1.  **Customer Request Received**
    * Input via email, web form, or sales rep.
    * Capture descriptions, quantities, and requirements.
2.  **Request Entry**
    * User enters the request into the AKSA application.
3.  **Natural Language Processing (NLP)**
    * Algorithms analyze and categorize items for matching.
4.  **Data Retrieval from ERP (Business Central)**
    * System searches the internal database for matching products in real-time.
5.  **Machine Learning (ML) Matching**
    * Predictive models validate matches against requirements.
6.  **Quote Compilation**
    * System generates a draft document for review and customization.
7.  **Follow-Up**
    * Gather customer feedback and make necessary adjustments.

---

## User Guide

### Step 1: Initial Configuration
Before using the app, users must configure the AI integration settings. Version 24.0.0.0 integrates with **OpenAI**, with **Azure OpenAI** support planned for future releases.

### Step 2: Communication Settings
Configure the communication parameters between Business Central and OpenAI. Navigate to the **AKSA AI Prompt Template** to create your workflow.

### Step 3: Prompt Templates
Create or modify templates via the template card. A standard workflow might include:
1.  **Prompt:** Text instructions for the AI.
2.  **Item Catalogue:** Provides required information from the ERP catalog.
3.  **Document Data:** Imported data from the related AKSA Draft Document.

### Step 4: Create Draft Document
Navigate to the **AKSA Draft Document List** and click **"New"**.

### Step 5: Field Completion
Complete the required fields:
* **Document No.:** Auto-generated.
* **Contact Name:** User-defined.
* **Type:** Dropdown (Sales, Purchase, or Service).
* **AI Prompt Template No.:** Select the desired processing logic.
* **Excel Desc./Qty Column No.:** Optional mapping to improve AI response quality.

### Step 6: Import Data
Click **"Import From Excel"**. This generates a specific data structure in the **Document Data** field. The format is flexible; the system can recognize lines even if specific columns aren't pre-mapped.

### Step 7: Process with AI
Click **"Process with AI"**.
* The OpenAI response is saved in the **AI Response** field.
* Document lines are populated with suggested items.
* **Note:** Users must verify the quality of AI suggestions. The original input remains in the **Input Description** field for comparison.

### Step 8: Multi-Item Suggestions
If the system identifies multiple potential matches, users can click the item number to view a list of alternatives.

### Step 9: Manual Refinement & Learning
If suggestions are incorrect, select the correct item from the catalog and click the **Flag** button. This selection will be prioritized in future processing.

### Step 10: Quote Generation
Press **"Evaluate to Quote"**. The system will generate a formal Sales, Purchase, or Service Quote based on the document type.

---

## Current Project Status
The application is functional for demonstrated workflows but is currently in the **Pilot/Testing phase**. We have one active customer currently testing the environment.

**Ongoing Development:**
* Integration with **Azure OpenAI**.
* Expanding recognition to image formats (**JPEG, JPG, PNG**).
* Developing advanced communication algorithms to improve suggestions based on historical user selections.
* Stress testing with large-scale real-world business data.