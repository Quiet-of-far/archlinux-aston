// SPDX-License-Identifier: GPL-2.0-only
/*
 * Read-only lookup of this phone's fingerprint trusted application names.
 * No TA loading, commands, biometric storage, GPIO or power changes.
 */
#include <linux/module.h>
#include <linux/firmware/qcom/qcom_scm.h>

static int __init aston_qsee_lookup_init(void)
{
	static const char * const names[] = { "uff_gx", "uff_spi" };
	unsigned int i;

	if (!qcom_scm_is_available())
		return -ENODEV;

	for (i = 0; i < ARRAY_SIZE(names); i++) {
		u32 id = 0;
		int ret = qcom_scm_qseecom_app_get_id(names[i], &id);

		pr_info("aston_qsee_lookup: %s ret=%d id=%u\n", names[i], ret, id);
	}
	return 0;
}

static void __exit aston_qsee_lookup_exit(void)
{
}
module_init(aston_qsee_lookup_init);
module_exit(aston_qsee_lookup_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Aston read-only QSEE application lookup diagnostic");
