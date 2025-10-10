-- Prescribers Database
-- For this exericse, you'll be working with a database derived from the Medicare Part D Prescriber Public Use File. 
-- More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.
-- 1.	a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--		Report the npi and the total number of claims.
--NEED: prescriber.npi, SUM(total_claim_count)

SELECT
	p.npi,
	SUM(rx.total_claim_count) AS total_claims
FROM prescriber p
LEFT JOIN prescription rx
USING (npi)
GROUP BY p.npi
HAVING SUM(rx.total_claim_count) IS NOT NULL
ORDER BY total_claims DESC
LIMIT 5;
--ANSWER: npi 1881634483 with 99,707 claims

-- 		b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
--		specialty_description, and the total number of claims.
--NEED: p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description, SUM(rx.total_claim_count)

SELECT
	p.nppes_provider_first_name AS first,
	p.nppes_provider_last_org_name AS last,
	p.specialty_description AS specialty,
	SUM(rx.total_claim_count) AS total_claims
FROM prescriber p
LEFT JOIN prescription rx
USING (npi)
GROUP BY p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description 
HAVING SUM(rx.total_claim_count) IS NOT NULL
ORDER BY total_claims DESC
LIMIT 5;
--Answer: Bruce Pendley, Family Practice with 99,707 claims

-- 2.	a. Which specialty had the most total number of claims (totaled over all drugs)?
--NEED: p.specialty_description, SUM(rx.total_claim_count)

SELECT
	p.specialty_description AS specialty,
	SUM(rx.total_claim_count) AS total_claims
FROM prescriber p
LEFT JOIN prescription rx
USING (npi)
WHERE rx.total_claim_count IS NOT NULL
GROUP BY p.specialty_description
ORDER BY total_claims DESC
LIMIT 5;


---
SELECT
	p1.specialty_description AS speciality,
	SUM(p2.total_claim_count) AS total_claim
FROM prescriber AS p1
LEFT JOIN prescription AS p2
USING (npi)
WHERE p2.drug_name IS NOT NULL
	OR p2.total_claim_count IS NOT NULL
GROUP BY speciality
ORDER BY total_claim DESC
LIMIT 5;

--Answer: Family Practice with 9,752,347 claims

-- 		b. Which specialty had the most total number of claims for opioids?
--NEED: p.specialty_description, SUM(rx.total_claim_count), d.opioid_flag (Y)

SELECT 
	p.specialty_description AS specialty,
	SUM(rx.total_claim_count) AS total_claims
FROM prescriber p
LEFT JOIN prescription as rx
USING (npi)
LEFT JOIN drug d
ON rx.drug_name = d.drug_name 
WHERE d.opioid_drug_flag = 'Y'
GROUP BY p.specialty_description
HAVING SUM(rx.total_claim_count) IS NOT NULL
ORDER BY total_claims DESC
LIMIT 5;
--Answer: Nurse Practitioners with 900,845

-- LAST	c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated 
--		prescriptions in the prescription table?

-- LAST d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- 3.	a. Which drug (generic_name) had the highest total drug cost?
--NEED: d.generic_name, SUM(rx.total_drug_cost)

SELECT
	d.generic_name AS drug_generic,
	SUM(rx.total_drug_cost) AS drug_cost
FROM drug d
LEFT JOIN prescription rx
USING (drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY d.generic_name
ORDER BY drug_cost DESC
LIMIT 5;
--Answer: Insulin at a total cost of 104,264,066.35

-- 		b. Which drug (generic_name) has the hightest total cost per day? 
--NEED: d.generic_name, SUM(rx.total_drug_cost) divided by SUM(rx.total_day_supply)

SELECT 
	d.generic_name,
	SUM(rx.total_drug_cost)/SUM(rx.total_day_supply) AS daily_cost
FROM prescription rx
LEFT JOIN drug d
USING (drug_name)
WHERE total_drug_cost IS NOT NULL
	AND total_day_supply IS NOT NULL
GROUP BY d.generic_name
ORDER BY daily_cost DESC
LIMIT 5;
--Answer: C1 Esterase Inhibitor at 3495.22/day


--		Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT 
	d.generic_name,
	ROUND(SUM(rx.total_drug_cost)/SUM(rx.total_day_supply), 2) AS daily_cost
FROM prescription rx
LEFT JOIN drug d
USING (drug_name)
WHERE total_drug_cost IS NOT NULL
	AND total_day_supply IS NOT NULL
GROUP BY d.generic_name
ORDER BY daily_cost DESC
LIMIT 5;

--Answer: C1 Esterase Inhibitor at 3495.22/day

-- 4.	a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' 
--		for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
--		and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. 
--		See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
--NEED: d.drug_name, d.opioid_drug_flag AS drug_type, d.antibiotic_drug_flag AS drug_type y="opioid" y="antibiotic" n="neither"

SELECT 
	d.drug_name,
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug d

--Answer: 3260 Rows

-- 		b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids 
--		or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
--NEED: SUM(rx.total_drug_cost) 

SELECT 
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END,
	TO_CHAR(SUM(rx.total_drug_cost), 'FM$999,999,999,999,.00') AS total_cost
FROM drug d
LEFT JOIN prescription rx
USING (drug_name)
GROUP BY d.opioid_drug_flag, d.antibiotic_drug_flag
ORDER BY total_cost DESC;
--Answer: Opioids

-- 5.	a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
--NEED: COUNT(cbsa.cbsa) WHERE fips_county.state = 'TN'
--96 in TN, 42 with city
SELECT 
	COUNT(cbsa.cbsa) AS cbsa_tn
FROM cbsa
JOIN fips_county
USING (fipscounty)
WHERE fips_county.state iLIKE '%TN%'
--Answer: 42

-- 		b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--NEED: cbsa.cbsaname, SUM(population.population) 

SELECT
	cbsa.cbsa,
	cbsa.cbsaname,
	SUM(population.population) AS total_pop
FROM cbsa
LEFT JOIN population
USING (fipscounty)
WHERE population.population IS NOT NULL
GROUP BY cbsa.cbsa, cbsa.cbsaname
ORDER BY total_pop DESC
--Answer: Largest: Nashville-Davidson-Murfreesboro-Franklin with 1830410
--		  Smallest: Morristown with 116352

-- 		c. What is the largest (in terms of population) county which is not included in a CBSA? 
--		Report the county name and population.
--NEED: fips_county.county, population.population
SELECT *
FROM fips_county 
FULL JOIN cbsa
USING (fipscounty)
FULL JOIN population
USING (fipscounty)
WHERE cbsa.cbsa IS NULL;

--???????? All Counties have NULL population???

SELECT 
	fc.county AS county,
	population.population AS population
FROM fips_county fc
FULL JOIN cbsa
USING (fipscounty)
FULL JOIN population
USING (fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC

-- 6.	a. Find all rows in the prescription table where total_claims is at least 3000. 
--		Report the drug_name and the total_claim_count.
--NEED: d.drug_name, SUM(rx.total_claim_count) AS claim_count

SELECT
	rx.drug_name,
	SUM(rx.total_claim_count)
FROM prescription rx
GROUP BY rx.drug_name
HAVING SUM(rx.total_claim_count) >= 3000
--Answer: 507 rows

-- 		b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT
	rx.drug_name,
	SUM(rx.total_claim_count),
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'non_opioid'
	END
FROM prescription rx
LEFT JOIN drug d
USING (drug_name)
GROUP BY rx.drug_name, d.opioid_drug_flag
HAVING SUM(rx.total_claim_count) >= 3000
--Answer: 517???

-- 		c. Add another column to you answer from the previous part which gives the prescriber first and last name associated 
--		with each row.

SELECT
	rx.drug_name,
	SUM(rx.total_claim_count) AS total_claims,
	p.nppes_provider_first_name || ' ' ||p.nppes_provider_last_org_name AS prescriber,
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'non_opioid'
	END
FROM prescription rx
FULL JOIN prescriber p
USING (npi)
FULL JOIN drug d
USING (drug_name)
GROUP BY rx.drug_name, prescriber, d.opioid_drug_flag
HAVING SUM(rx.total_claim_count) >= 3000
ORDER BY total_claims DESC
--Answer: 38 rows?!?!

-- 7.	The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number 
--		of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- 		a. First, create a list of all npi/drug_name combinations for pain management specialists 
--		(specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
--		where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. 
--		You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
--NEED: p.npi, d.drug_name (cross join?), where p.specialty_description = 'Pain Management', p.nppes_provider_city = 'Nashville'
--		AND d.opioid_drug_flag = 'Y'

SELECT
	p.npi,
	p.specialty_description,
	d.drug_name,
	CASE 
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'non_opioid'
	END
FROM prescriber p
UNION ALL drug d
WHERE p.specialty_description = 'Pain Mangement'
	AND p.nppes_provider_city = 'Nashville'

-- 		b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not 
--		the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- 		c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
--		Hint - Google the COALESCE function.