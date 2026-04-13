/**
 * AnonymousScript_ReplaceTrackerQueryField.apex
 *
 * Ready-to-run Anonymous Apex script.
 *
 * How to use:
 *   1. Open Salesforce Developer Console  (Setup → Developer Console)
 *      OR use VS Code with Salesforce Extension Pack:
 *        SFDX: Execute Anonymous Apex with Editor Contents
 *   2. Paste this entire file into the "Enter Apex Code" window.
 *   3. Update OLD_FIELD and NEW_FIELD to match your actual field API names.
 *   4. Run in PREVIEW_ONLY mode first to confirm the changes before committing.
 *   5. Set PREVIEW_ONLY = false and run again to apply the changes.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * CONFIGURATION — update these three values before running
 * ─────────────────────────────────────────────────────────────────────────────
 */

// API name of the field that has been (or will be) deleted
final String OLD_FIELD = 'Deleted_Field__c';

// API name of the replacement field
final String NEW_FIELD = 'Replacement_Field__c';

// Set to true to preview changes without saving them.
// Set to false to actually update the Tracker records.
final Boolean PREVIEW_ONLY = true;

// ─────────────────────────────────────────────────────────────────────────────
// Script body — no changes needed below this line
// ─────────────────────────────────────────────────────────────────────────────

System.debug('=== ReplaceTrackerQueryField ===');
System.debug('Old field : ' + OLD_FIELD);
System.debug('New field : ' + NEW_FIELD);
System.debug('Mode      : ' + (PREVIEW_ONLY ? 'PREVIEW (no DML)' : 'APPLY (DML enabled)'));
System.debug('');

if (PREVIEW_ONLY) {
    List<Map<String, String>> changes =
        ReplaceTrackerQueryField.previewReplacements(OLD_FIELD, NEW_FIELD);

    if (changes.isEmpty()) {
        System.debug('No Tracker records reference "' + OLD_FIELD + '". Nothing to do.');
    } else {
        System.debug('The following ' + changes.size()
            + ' field value(s) would be updated:');
        for (Map<String, String> entry : changes) {
            System.debug(
                '  Tracker "' + entry.get('name') + '" (' + entry.get('id') + ')' +
                '  field=' + entry.get('field') +
                '  BEFORE="' + entry.get('before') + '"' +
                '  AFTER="'  + entry.get('after')  + '"'
            );
        }
        System.debug('');
        System.debug('Set PREVIEW_ONLY = false and re-run to apply these changes.');
    }
} else {
    Integer updated = ReplaceTrackerQueryField.replaceFieldInAllTrackers(
        OLD_FIELD, NEW_FIELD);
    System.debug('Done. ' + updated
        + ' Tracker record(s) updated successfully.');
}
