# Swissmetro SA: Multinomial Logit Model for Modal Choice Analysis

## Project Context
This repository contains the midterm report analysis for the **Urban Transportation Planning and Analysis (UTPA)** course at Tokyo University.  
The project assesses the potential impact and demand for a major, hypothetical transport innovation: the **Swissmetro SA**, an underground mag-lev (magnetic levitation) system designed to connect major Swiss cities at speeds up to 500 km/h.

---

## Feature Details

| Feature | Details |
|---------|---------|
| **Data Source** | Stated Choice Survey Data |
| **Survey Period** | March 1998, Switzerland |
| **Sample Size** | 1191 respondents |
| **Transport Alternatives** | Rail (Train), Swissmetro (SM), Car (for car owners only) |
| **Key Variables** | Cost (CO), Travel Time (TT), Demographics, General Abonnement (GA) pass ownership |

---

## Key Concepts & Methodology

### Multinomial Logit Model (MNL)
- The core modeling technique is the **Multinomial Logit Model (MNL)**.  
- MNL is used to analyze **discrete choice** (selecting one alternative from a set) by estimating parameters ($\beta$) of a utility function explaining why a traveler chooses a specific mode.

### General Abonnement (GA) Pass
- GA pass allows unlimited travel on most Swiss train lines.  
- Its inclusion helps understand how a **pre-paid, non-recoverable travel cost** influences the choice between public transport (Rail/SM) and private transport (Car).

### Elasticities
- Measure the sensitivity of demand (probability of choosing a mode) to changes in variables like cost or travel time.
- **Direct Elasticity ($\epsilon^D$):** Effect of a change in a mode's attribute on its own choice probability.  
- **Cross Elasticity ($\epsilon^C$):** Effect of a change in one mode's attribute on another mode’s choice probability.

### Value of Travel Time Saving (VTTS)
- Calculated as the ratio of the travel time coefficient to the travel cost coefficient:  
  $ \text{VTTS} = \beta_{TT} / \beta_{CO} $
- Represents the monetary amount travelers are willing to pay to save one unit of travel time.

---

## Core Analysis Findings

### 1. Model Goodness-of-Fit and Coefficients
- The initial MNL model demonstrated a good fit, with aggregate choice probabilities closely matching observed sample ratios (approx. **57% for Swissmetro choosing SM**).  
- Including the GA pass variable was necessary; excluding it resulted in counter-intuitive, positive cost coefficients for rail and Swissmetro.

### 2. Demand Sensitivity (Elasticities)

| Metric | Result | Interpretation |
|--------|--------|----------------|
| Direct Elasticity for SM Travel Time | Approx. -0.55% | A 1% increase in SM travel time decreases the probability of choosing SM by 0.55%. |
| Cross Elasticity (SM TT → Car) | Approx. +0.95% | A 1% increase in SM travel time increases the probability of choosing Car by 0.95%, showing a substitution effect. |

### 3. Value of Travel Time Saving (VTTS)
- **Rail (Train):** Highest VTTS (~14.54)  
- **Swissmetro (SM):** High VTTS (~13.65)  
- **Car:** Lowest VTTS (~2.97)

### 4. Impact of Luggage
- Including the **LUGGAGE** variable improved model goodness-of-fit ($\rho^2$ increased).  
- The Car coefficient with luggage had the highest negative value, suggesting luggage strongly reduces Car choice probability compared to Train or Swissmetro.

---

## Conclusion
The analysis confirms a **strong potential demand for the Swissmetro**, especially among current public transport users.  
Advanced econometric models like MNL are essential for accurately forecasting demand by accounting for **pre-paid passes**, **trip-specific needs** (e.g., luggage), and other complex factors.
