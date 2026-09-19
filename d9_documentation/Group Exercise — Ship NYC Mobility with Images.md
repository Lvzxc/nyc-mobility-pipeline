# Group Exercise — Ship NYC Mobility

## Task

Take the pipeline you built last week and move a change through the production workflow.

## Your Mission

**CHANGE → TEST → COMMIT → PUSH → DEPLOY → RUN → VERIFY**

### 1. Clone

In VS Code, clone your repository using Git:

<img width="586" height="70" alt="2" src="https://github.com/user-attachments/assets/595e17e3-1d48-4963-b721-978e43f1e4ad" />
<img width="580" height="65" alt="1" src="https://github.com/user-attachments/assets/219d4a7c-4047-4e19-a99a-6f48545ca14c" />

**Clone**

### 2. Change

Modify `clean_taxi_zones` to standardize borough and zone using:

<img width="586" height="342" alt="3" src="https://github.com/user-attachments/assets/e5140621-e2c5-44c5-9c14-0ef2b85c642c" />

```sql
INITCAP(TRIM())
```

### 3. Test

Run Silver DQ checks, verify standardized values, and confirm row counts remain unchanged.

<img width="530" height="365" alt="4" src="https://github.com/user-attachments/assets/1ecf9c08-02a4-4aea-bc93-0e3e7e9858df" />

### 4. Commit + Push

Commit the SQL change and push the feature branch to GitHub.

<img width="521" height="282" alt="5" src="https://github.com/user-attachments/assets/af7d6a48-2389-4356-8f01-b79aed5adf98" />

### 5. GitHub

Version-controlled change becomes available for deployment.

<img width="590" height="720" alt="6" src="https://github.com/user-attachments/assets/0a3c247d-e24d-4a18-bdf5-7f4db8dcb773" />

### 6. Databricks

Production workflow receives the deployed SQL transformation.

<img width="522" height="337" alt="7" src="https://github.com/user-attachments/assets/99691c53-f8b7-4735-82cd-972dc046a428" />
### 7. Run

Run the pipeline and update: `nyc.nyc_silver.taxi_zones_silver`

<img width="482" height="355" alt="8" src="https://github.com/user-attachments/assets/a8fac216-422e-4b35-9d58-29acefa446e6" />

### 8. Verify

Confirm borough/zone formatting, expected row count, and passing DQ checks.

<img width="630" height="637" alt="9" src="https://github.com/user-attachments/assets/73a91139-4ef4-4d89-9c26-630c890b3b20" />


