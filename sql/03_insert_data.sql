-- Insert reference data into gold_types

INSERT INTO raw.gold_types (
    gold_type_id,
    gold_type_name
)
VALUES
    (1, '24K'),
    (2, '22K'),
    (3, '18K'),
    (4, '14K')
ON CONFLICT (gold_type_id) DO NOTHING;

-- Insert synthetic branch data

INSERT INTO raw.branches (
    branch_id,
    branch_name,
    city,
    opening_date
)
VALUES
    (1, 'Downtown Branch', 'Yangon', '2015-03-15'),
    (2, 'Mandalay Central Branch', 'Mandalay', '2017-06-20'),
    (3, 'Capital Branch', 'Naypyidaw', '2019-09-10'),
    (4, 'Taunggyi Branch', 'Taunggyi', '2021-01-25'),
    (5, 'Mawlamyine Branch', 'Mawlamyine', '2022-08-12')
ON CONFLICT (branch_id) DO NOTHING;