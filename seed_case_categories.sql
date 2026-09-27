-- =========================================================================
-- seed_case_categories.sql
-- Strictly matched to User Specification for 1-5 and Part 6
-- Schema: maharashtra
-- =========================================================================

SET search_path TO maharashtra, public;

-- Clean existing category links & categories
DELETE FROM maharashtra.case_category_links;
DELETE FROM maharashtra.category_field_overrides;
DELETE FROM maharashtra.case_categories;
DELETE FROM maharashtra.case_category_groups;

-- 1. Create Groups
INSERT INTO maharashtra.case_category_groups (group_id, group_name, group_code, display_order)
VALUES 
    (1, '1 to 5', 'I TO V', 1),
    (2, 'Part 6', 'VI', 2)
ON CONFLICT (group_id) DO UPDATE 
SET group_name = EXCLUDED.group_name, group_code = EXCLUDED.group_code, display_order = EXCLUDED.display_order;

-- 2. Insert Categories
INSERT INTO maharashtra.case_categories (group_id, category_name, category_code, display_order, is_active)
VALUES
    -- =====================================================================
    -- A. TABS UNDER '1 TO 5' ONLY (18 items)
    -- =====================================================================
    (1, 'Murder', '101', 1, TRUE),
    (1, 'Attempt to Murder', '102', 2, TRUE),
    (1, 'Dacoity', '103', 3, TRUE),
    (1, 'Robbery', '104', 4, TRUE),
    (1, 'HBT', '105', 5, TRUE),
    (1, 'Riot', '106', 6, TRUE),
    (1, 'Unlawful Assembly', '107', 7, TRUE),
    (1, 'CBT', '108', 8, TRUE),
    (1, 'Cheating', '109', 9, TRUE),
    (1, 'Mischief', '110', 10, TRUE),
    (1, 'Assault on Public Servant', '111', 11, TRUE),
    (1, 'Rape', '112', 12, TRUE),
    (1, 'Molestation', '113', 13, TRUE),
    (1, 'Extortion', '114', 14, TRUE),
    (1, 'IPC (A) 304', '115', 15, TRUE),
    (1, '498 (A) IPC', '116', 16, TRUE),
    (1, 'Other IPC', '117', 17, TRUE),
    (1, 'Chain Snatching', '118', 18, TRUE),

    -- =====================================================================
    -- B. TABS UNDER '1 TO 5' THAT ALSO HAVE A SEPARATE TAB (10 items)
    --    (Inside '1 to 5' group, group_id = 1)
    -- =====================================================================
    (1, 'Theft', '119', 19, TRUE),
    (1, 'Kidnapping', '120', 20, TRUE),
    (1, 'Hurt', '121', 21, TRUE),
    (1, 'Sand Theft', '122', 22, TRUE),
    (1, 'Two/Four Wheeler Theft', '123', 23, TRUE),
    (1, 'Missing', '124', 24, TRUE),
    (1, 'Crime Against Women', '125', 25, TRUE),
    (1, 'Accident', '126', 26, TRUE),
    (1, 'Sec 156(3)/175(3)(BNSS)', '127', 27, TRUE),
    (1, 'Coin', '128', 28, TRUE),

    -- =====================================================================
    -- C. STANDALONE TWINS FOR 1-TO-5 DUAL-PRESENCE ITEMS (group_id = NULL)
    -- =====================================================================
    (NULL, 'Theft', 'STAND_THEFT', 29, TRUE),
    (NULL, 'Kidnapping', 'STAND_KIDNAP', 30, TRUE),
    (NULL, 'Hurt', 'STAND_HURT', 31, TRUE),
    (NULL, 'Sand Theft', 'STAND_SAND', 32, TRUE),
    (NULL, 'Two/Four Wheeler Theft', 'STAND_VEHICLE', 33, TRUE),
    (NULL, 'Missing', 'STAND_MISSING', 34, TRUE),
    (NULL, 'Crime Against Women', 'STAND_WOMEN', 35, TRUE),
    (NULL, 'Accident', 'STAND_ACCIDENT', 36, TRUE),
    (NULL, 'Sec 156(3)/175(3)(BNSS)', 'STAND_BNSS_SEC', 37, TRUE),
    (NULL, 'Coin', 'STAND_COIN', 38, TRUE),

    -- =====================================================================
    -- D. STANDALONE-ONLY CATEGORIES (3 items)
    -- =====================================================================
    (NULL, 'Suicide', 'STAND_SUICIDE', 39, TRUE),
    (NULL, 'A.D.', 'STAND_AD', 40, TRUE),
    (NULL, 'N.C.', 'STAND_NC', 41, TRUE),

    -- =====================================================================
    -- E. TABS UNDER 'PART 6' THAT ALSO HAVE A SEPARATE TAB (9 items)
    --    (Inside Part 6 group, group_id = 2)
    -- =====================================================================
    (2, 'ST Drugs', '601', 42, TRUE),
    (2, 'Prohibition', '602', 43, TRUE),
    (2, 'Gambling', '603', 44, TRUE),
    (2, 'POCSO', '604', 45, TRUE),
    (2, 'NDPS', '605', 46, TRUE),
    (2, 'Gowans', '606', 47, TRUE),
    (2, 'IT Act', '607', 48, TRUE),
    (2, 'M.V Act', '608', 49, TRUE),
    (2, 'UAPA', '609', 50, TRUE),

    -- =====================================================================
    -- F. STANDALONE TWINS FOR PART 6 DUAL-PRESENCE ITEMS (group_id = NULL)
    -- =====================================================================
    (NULL, 'ST Drugs', 'STAND_ST_DRUGS', 51, TRUE),
    (NULL, 'Prohibition', 'STAND_PROHIBITION', 52, TRUE),
    (NULL, 'Gambling', 'STAND_GAMBLING', 53, TRUE),
    (NULL, 'POCSO', 'STAND_POCSO', 54, TRUE),
    (NULL, 'NDPS', 'STAND_NDPS', 55, TRUE),
    (NULL, 'Gowans', 'STAND_GOWANS', 56, TRUE),
    (NULL, 'IT Act', 'STAND_IT_ACT', 57, TRUE),
    (NULL, 'M.V Act', 'STAND_MV_ACT', 58, TRUE),
    (NULL, 'UAPA', 'STAND_UAPA', 59, TRUE);

-- =====================================================================
-- 3. ACTS, SECTIONS & SUBSECTIONS MAPPING FOR ROBBERY & DACOITY
-- =====================================================================

-- Insert Act
INSERT INTO maharashtra.acts (act_id, act_code, act_name, is_active)
VALUES 
    (1, 'BNS', 'Bharatiya Nyaya Sanhita 2023', TRUE),
    (2, 'IPC', 'Indian Penal Code 1860', TRUE)
ON CONFLICT (act_code) DO NOTHING;

-- Insert Form Templates
INSERT INTO maharashtra.field_templates (template_id, template_name, is_active)
VALUES
    (3, 'Dacoity Form Template', TRUE),
    (4, 'Robbery Form Template', TRUE)
ON CONFLICT (template_id) DO NOTHING;

-- Insert Sections under BNS 2023
INSERT INTO maharashtra.act_sections (section_id, act_id, section_number, title, description, bailable_type, is_active)
VALUES
    (309, 1, '309', 'Robbery', 'Robbery under BNS 2023 (Corresponds to IPC 390, 392, 393, 394)', 'Non-Bailable', TRUE),
    (310, 1, '310', 'Dacoity', 'Dacoity under BNS 2023 (Corresponds to IPC 391, 395, 396, 399, 400, 402)', 'Non-Bailable', TRUE),
    (311, 1, '311', 'Robbery, or dacoity, with attempt to cause death or grievous hurt', 'Corresponds to IPC 397', 'Non-Bailable', TRUE),
    (312, 1, '312', 'Attempt to commit robbery or dacoity when armed with deadly weapon', 'Corresponds to IPC 398', 'Non-Bailable', TRUE)
ON CONFLICT (act_id, section_number) DO UPDATE
SET title = EXCLUDED.title, description = EXCLUDED.description;

-- Insert Subsections for Robbery (Section 309) & Dacoity (Section 310)
INSERT INTO maharashtra.act_subsections (section_id, subsection_code, description, is_active)
VALUES
    -- Robbery (BNS Section 309)
    (309, '1', 'Robbery definition / theft in order to committing theft (IPC 390)', TRUE),
    (309, '2', 'Robbery definition / extortion in order to committing extortion (IPC 390)', TRUE),
    (309, '3', 'Robbery definition / wrongful restraint or fear of instant hurt (IPC 390)', TRUE),
    (309, '4', 'Punishment for robbery (IPC 392)', TRUE),
    (309, '5', 'Attempt to commit robbery (IPC 393)', TRUE),
    (309, '6', 'Voluntarily causing hurt in committing robbery (IPC 394)', TRUE),

    -- Dacoity (BNS Section 310)
    (310, '1', 'Dacoity definition (IPC 391)', TRUE),
    (310, '2', 'Punishment for dacoity (IPC 395)', TRUE),
    (310, '3', 'Dacoity with murder (IPC 396)', TRUE),
    (310, '4', 'Making preparation to commit dacoity (IPC 399)', TRUE),
    (310, '5', 'Punishment for belonging to gang of dacoits (IPC 400)', TRUE),
    (310, '6', 'Assembling for purpose of committing dacoity (IPC 402)', TRUE)
ON CONFLICT DO NOTHING;

-- Map Sections to Field Templates
INSERT INTO maharashtra.section_field_templates (section_id, template_id)
VALUES
    (309, 4), -- Robbery -> Robbery Form Template
    (310, 3), -- Dacoity -> Dacoity Form Template
    (311, 4), -- Robbery/Dacoity with death attempt -> Robbery Form Template
    (312, 4)  -- Attempt to commit robbery/dacoity armed -> Robbery Form Template
ON CONFLICT DO NOTHING;

-- Verify row count
SELECT COUNT(*) AS total_case_categories FROM maharashtra.case_categories;
SELECT COUNT(*) AS total_act_sections FROM maharashtra.act_sections;
SELECT COUNT(*) AS total_act_subsections FROM maharashtra.act_subsections;
