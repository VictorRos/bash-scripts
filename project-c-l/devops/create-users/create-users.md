# Création des utilisateurs

Cette documentation explique comment sont créés les utilisateurs sur les différents tenants et environnements de la souscription `SAAS-8307-DEV`.

## Tenants

Pour simuler ce qu'il y a en production, Fabien Gouineau a créé 3 tenants :

- `sandboxloop` : Tenant pour le cabinet KPMG
- `sandboxloopdev` : Tenant pour les cabinet non KPMG
- `sandboxloopclient` : Tenant pour les clients des cabinets (pour le collaboratif)

## Utilisateurs

Pour chaque tenant cités ci-dessus, les utilisateurs suivants seront créés.

| Email                                              | Profil | Commentaire                                                           |
|----------------------------------------------------|:------:|-----------------------------------------------------------------------|
| `admin-securityteam@__TENANT__.onmicrosoft.com`    |        | Pas de compte applicatif, Administrateur général dans l'Azure AD      |
| `admin-sharepoint@__TENANT__.onmicrosoft.com`      |        | Pas de compte applicatif, Administrateur SharePoint dans l'Azure AD   |
| `admin-users@__TENANT__.onmicrosoft.com`           |        | Pas de compte applicatif, Administrateur utilisateurs dans l'Azure AD |
| `profil1-__DOMAINE__@__TENANT__.onmicrosoft.com`   |  1.0   | Chef d'entreprise                                                     |
| `profil2-__DOMAINE__@__TENANT__.onmicrosoft.com`   |  2.0   | Comptable                                                             |
| `profil2.5-__DOMAINE__@__TENANT__.onmicrosoft.com` |  2.5   | Profil CAC                                                            |
| `profil3-__DOMAINE__@__TENANT__.onmicrosoft.com`   |  3.0   | Collaborateur                                                         |
| `profil4-__DOMAINE__@__TENANT__.onmicrosoft.com`   |  4.0   | Expert comptable                                                      |
| `profil4.1-__DOMAINE__@__TENANT__.onmicrosoft.com` |  4.1   | Saisie aide                                                           |
| `profil4.2-__DOMAINE__@__TENANT__.onmicrosoft.com` |  4.2   | Saisie OCR                                                            |
| `profil5-__DOMAINE__@__TENANT__.onmicrosoft.com`   |  5.0   | Administrateur de domaine                                             |
| `profil5.1-__DOMAINE__@__TENANT__.onmicrosoft.com` |  5.1   | Support / Maintenance                                                 |
| `<qa>-__DOMAINE__@__TENANT__.onmicrosoft.com`      |  5.1   | Les QA auront un profil 5.1                                           |
| `<dev>-__DOMAINE__@__TENANT__.onmicrosoft.com`     |  5.1   | Les Dev auront un profil 5.1                                          |
| `<devops>-__DOMAINE__@__TENANT__.onmicrosoft.com`  |  6.0   | Les DevOps auront un profil 6.0                                       |

_Notes :_

- `__DOMAINE__` représente le domaine du cabinet.
- `__TENANT__` représente le tenant avec le suffixe `.onmicrosoft.com`.
- `<qa>`, `<dev>` et `<devops>` représentent le préfixe des comptes Cegid.
