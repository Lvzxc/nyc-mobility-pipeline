# Group Exercise — Ship NYC Mobility

## Task

Take the pipeline you built last week and move a change through the production workflow.

## Your Mission

**CHANGE → TEST → COMMIT → PUSH → DEPLOY → RUN → VERIFY**

### 1. Clone

In VS Code, clone your repository using Git:

**Clone**

### 2. Change

Modify `clean_taxi_zones` to standardize borough and zone using:

```sql
INITCAP(TRIM())
```

### 3. Test

Run Silver DQ checks, verify standardized values, and confirm row counts remain unchanged.

### 4. Commit + Push

Commit the SQL change and push the feature branch to GitHub.

### 5. GitHub

Version-controlled change becomes available for deployment.

### 6. Databricks

Production workflow receives the deployed SQL transformation.

### 7. Run

Run the pipeline and update:

`nyc.nyc_silver.taxi_zones_silver`

### 8. Verify

Confirm borough/zone formatting, expected row count, and passing DQ checks.

## Images from the Original PDF

![Original PDF image — page 1](ship_nyc_mobility_assets/page-1-image-1.png)

![Original PDF image — page 1](ship_nyc_mobility_assets/page-1-image-2.png)

![Original PDF image — page 1](ship_nyc_mobility_assets/page-1-image-3.png)

![Original PDF image — page 2](ship_nyc_mobility_assets/page-2-image-1.png)

![Original PDF image — page 2](ship_nyc_mobility_assets/page-2-image-2.png)

![Original PDF image — page 3](ship_nyc_mobility_assets/page-3-image-1.png)

![Original PDF image — page 3](ship_nyc_mobility_assets/page-3-image-2.png)

![Original PDF image — page 4](ship_nyc_mobility_assets/page-4-image-1.png)

![Original PDF image — page 4](ship_nyc_mobility_assets/page-4-image-2.png)

![Original PDF image — page 5](ship_nyc_mobility_assets/page-5-image-1.png)

![Original PDF image — page 5](ship_nyc_mobility_assets/page-5-image-2.png)

