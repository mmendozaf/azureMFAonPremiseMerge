# azureMFAonPremiseMerge

The main aim of this script is to help the migration the DB of users from azure MFA on Premise to Azure AD MFA. Basically the script check the users on AD, get the UPN and the values of MFA settings from Azure.

To execute the script ./mergeMFA.ps  <CSV_file_exported_from_Azure_MFA_On_premise>
As an output generate a csv with the data collected.
