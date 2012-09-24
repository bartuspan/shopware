-- Re import shops
TRUNCATE TABLE `s_core_shops`;
INSERT INTO `s_core_shops` (`id`, `name`, `host`, `hosts`, `template_id`, `document_template_id`, `category_id`, `locale_id`, `currency_id`, `customer_group_id`, `default`, `fallback_id`)
SELECT
	id, name,
	IF(`domainaliase`='', NULL, TRIM(SUBSTRING_INDEX(`domainaliase`, '\n', 1))) as host,
	IF(`domainaliase`='', NULL, domainaliase) as hosts,
	IFNULL((SELECT id FROM s_core_templates WHERE m.template LIKE CONCAT('%', template)), 11) as `template_id`,
    IFNULL((SELECT id FROM s_core_templates WHERE m.doc_template LIKE CONCAT('%', template)), 11) as `document_template_id`,
	parentID as `category_id`,
	locale as `locale_id`,
	defaultcurrency as `currency_id`,
	(SELECT id FROM s_core_customergroups WHERE groupkey=defaultcustomergroup) as `customer_group_id`,
	`default`,
    IF(fallback=0, NULL, fallback) as `fallback_id`
FROM s_core_multilanguage m;
UPDATE `s_core_shops` SET `base_path` = NULL, `secure_base_path` = NULL;

-- Re import shop currencies
TRUNCATE TABLE `s_core_shop_currencies`;
INSERT INTO `s_core_shop_currencies`
SELECT m.id, c.id
FROM s_core_multilanguage m
JOIN s_core_currencies c
ON c.id = m.switchCurrencies
OR m.switchCurrencies LIKE CONCAT(c.id, '|%')
OR m.switchCurrencies LIKE CONCAT('%|', c.id)
OR m.switchCurrencies LIKE CONCAT('%|', c.id, '|%');

-- Fix old iso codes
UPDATE s_core_translations t, s_core_multilanguage m
SET t.objectlanguage=m.id
WHERE t.objectlanguage=m.isocode;

UPDATE s_order o, s_core_multilanguage m
SET o.language=m.id
WHERE o.language=m.isocode;

UPDATE s_user u, s_core_multilanguage m
SET u.language=m.id
WHERE u.language=m.isocode;

UPDATE s_core_multilanguage m
SET m.isocode=m.id;

UPDATE `s_core_shops` SET `default` = IF(`id`=1, 1, 0);
SET @value = (SELECT `value` FROM `s_core_config` WHERE `name` LIKE 'sHOST');
UPDATE `s_core_shops` SET `host` = TRIM(@value) WHERE `default`=1;
SET @value = (SELECT REPLACE(`value`, @value, '') FROM `s_core_config` WHERE `name` LIKE 'sBASEPATH');
UPDATE `s_core_shops` SET `base_path` = TRIM(@value) WHERE `base_path` IS NULL AND `main_id` IS NULL;
UPDATE `s_core_shops` SET `base_path` = NULL WHERE `base_path` = '';