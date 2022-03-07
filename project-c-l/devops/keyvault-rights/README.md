# Key Vaults rights Matrix

Rights are defined in a JSON file that **MUST BE KEPT UP TO DATE**.

## Structure

```jsonc
{
  "groups": [
    {
      "name": "<Azure AD group name>",
      "id": "<Azure AD group ID>",
      "keyVaults": [
        {
          "name": "<Key Vault name>",
          "subscription": "<Key Vault subscription>",
          "resourceGroup": "<Key Vault resource group>",
          "certificatePermissions": "<Rights separated by a space>",
          "keyPermissions": "<Rights separated by a space>",
          "secretPermissions": "<Rights separated by a space>",
        },
        // Other Key Vaults
      ]
    },
    // Other Azure AD groups
  ]
}
```

## Current Azure AD groups

- `GRP-LOOP-DEV-CONTRIBUTORS`
- `GRP-LOOP-DEV-OWNERS`
- `GRP-LOOP-DEV`
- `GRP-LOOP-DOC`
- `GRP-LOOP-LEAD-DEV`
- `GRP-LOOP-QA`
- `GRP-LOOP-SAAS`
- `GRP-PIA-DEV`
- `GRP-YUPANA-DEV`

## Rules

1. All Azure AD groups must have at least rights `get` and `list`.

2. Add new Azure AD group in **alphabetical order**

3. Add new Azure Key Vault by respecting number order (for example 20th after 19th)

## FAQ

1. How can I know which permissions I can use?

   ```bash
   az keyvault set-policy -h
   ```

2. If I have a question, who can I ask?

   Super-DevOps team :)
