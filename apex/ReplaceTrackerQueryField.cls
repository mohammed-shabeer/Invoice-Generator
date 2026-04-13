/**
 * ReplaceTrackerQueryField
 *
 * Utility class for Sitetracker orgs.
 *
 * After deleting a custom field that was referenced inside Tracker records
 * (sitetracker__Tracker__c), call replaceFieldInAllTrackers() to swap every
 * occurrence of the old field API name for the new (replacement) field API
 * name across the following Tracker fields:
 *
 *   - sitetracker__Query_Fields__c  (comma-separated list of field API names)
 *   - sitetracker__Filter_Field__c  (single field API name)
 *   - sitetracker__Sort_Field__c    (single field API name)
 *
 * The replacement is token-exact and case-insensitive, so a field named
 * "Status__c" will NOT accidentally modify "Old_Status__c".
 *
 * Usage (anonymous Apex / Developer Console):
 *   ReplaceTrackerQueryField.replaceFieldInAllTrackers(
 *       'Old_Field__c',       // field being removed
 *       'New_Field__c'        // replacement field
 *   );
 *
 * To preview changes without committing them use previewReplacements().
 */
public with sharing class ReplaceTrackerQueryField {

    // -----------------------------------------------------------------------
    // Public entry points
    // -----------------------------------------------------------------------

    /**
     * Replaces every occurrence of oldFieldApiName with newFieldApiName in
     * all Tracker records and saves the changes.
     *
     * @param oldFieldApiName  API name of the field that was (or will be) deleted.
     * @param newFieldApiName  API name of the replacement field.
     * @return                 Number of Tracker records that were updated.
     */
    public static Integer replaceFieldInAllTrackers(
            String oldFieldApiName,
            String newFieldApiName) {

        validateParams(oldFieldApiName, newFieldApiName);

        List<sitetracker__Tracker__c> toUpdate = buildUpdates(
            queryAllTrackers(), oldFieldApiName, newFieldApiName);

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return toUpdate.size();
    }

    /**
     * Dry-run version of replaceFieldInAllTrackers.
     * Returns a list of maps describing which records would change and how,
     * without performing any DML.
     *
     * Each map contains:
     *   'id'        => Tracker record Id
     *   'name'      => Tracker Name
     *   'field'     => which Tracker field would change
     *   'before'    => current value
     *   'after'     => value after replacement
     *
     * @param oldFieldApiName  API name of the field that was (or will be) deleted.
     * @param newFieldApiName  API name of the replacement field.
     * @return                 List of change-description maps (empty if nothing would change).
     */
    public static List<Map<String, String>> previewReplacements(
            String oldFieldApiName,
            String newFieldApiName) {

        validateParams(oldFieldApiName, newFieldApiName);

        List<Map<String, String>> preview = new List<Map<String, String>>();

        for (sitetracker__Tracker__c tracker : queryAllTrackers()) {
            preview.addAll(
                buildPreviewEntries(tracker, oldFieldApiName, newFieldApiName));
        }

        return preview;
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    private static void validateParams(String oldField, String newField) {
        if (String.isBlank(oldField)) {
            throw new IllegalArgumentException(
                'oldFieldApiName must not be blank.');
        }
        if (String.isBlank(newField)) {
            throw new IllegalArgumentException(
                'newFieldApiName must not be blank.');
        }
    }

    /** Returns all Tracker records with the fields we care about. */
    private static List<sitetracker__Tracker__c> queryAllTrackers() {
        return [
            SELECT Id,
                   Name,
                   sitetracker__Query_Fields__c,
                   sitetracker__Filter_Field__c,
                   sitetracker__Sort_Field__c
            FROM   sitetracker__Tracker__c
            WITH   SECURITY_ENFORCED
        ];
    }

    /**
     * Applies replacements to a list of Tracker records and returns only the
     * ones that were actually modified.
     */
    private static List<sitetracker__Tracker__c> buildUpdates(
            List<sitetracker__Tracker__c> trackers,
            String oldField,
            String newField) {

        List<sitetracker__Tracker__c> changed =
            new List<sitetracker__Tracker__c>();

        for (sitetracker__Tracker__c t : trackers) {
            Boolean modified = false;

            String newQueryFields = replaceTokenInList(
                t.sitetracker__Query_Fields__c, oldField, newField);
            if (newQueryFields != t.sitetracker__Query_Fields__c) {
                t.sitetracker__Query_Fields__c = newQueryFields;
                modified = true;
            }

            String newFilterField = replaceTokenExact(
                t.sitetracker__Filter_Field__c, oldField, newField);
            if (newFilterField != t.sitetracker__Filter_Field__c) {
                t.sitetracker__Filter_Field__c = newFilterField;
                modified = true;
            }

            String newSortField = replaceTokenExact(
                t.sitetracker__Sort_Field__c, oldField, newField);
            if (newSortField != t.sitetracker__Sort_Field__c) {
                t.sitetracker__Sort_Field__c = newSortField;
                modified = true;
            }

            if (modified) {
                changed.add(t);
            }
        }

        return changed;
    }

    /** Builds preview entries for a single Tracker record (no DML). */
    private static List<Map<String, String>> buildPreviewEntries(
            sitetracker__Tracker__c tracker,
            String oldField,
            String newField) {

        List<Map<String, String>> entries = new List<Map<String, String>>();

        entries.addAll(previewSingleField(
            tracker, 'sitetracker__Query_Fields__c',
            tracker.sitetracker__Query_Fields__c,
            replaceTokenInList(tracker.sitetracker__Query_Fields__c, oldField, newField)));

        entries.addAll(previewSingleField(
            tracker, 'sitetracker__Filter_Field__c',
            tracker.sitetracker__Filter_Field__c,
            replaceTokenExact(tracker.sitetracker__Filter_Field__c, oldField, newField)));

        entries.addAll(previewSingleField(
            tracker, 'sitetracker__Sort_Field__c',
            tracker.sitetracker__Sort_Field__c,
            replaceTokenExact(tracker.sitetracker__Sort_Field__c, oldField, newField)));

        return entries;
    }

    private static List<Map<String, String>> previewSingleField(
            sitetracker__Tracker__c tracker,
            String fieldLabel,
            String before,
            String after) {

        List<Map<String, String>> result = new List<Map<String, String>>();
        if (before != after) {
            result.add(new Map<String, String>{
                'id'     => tracker.Id,
                'name'   => tracker.Name,
                'field'  => fieldLabel,
                'before' => before,
                'after'  => after
            });
        }
        return result;
    }

    /**
     * Replaces every token that exactly equals oldToken (case-insensitive) in a
     * comma-separated list. Preserves the original delimiter and spacing style.
     *
     * Examples:
     *   "Field_A__c, Old__c, Field_B__c" -> "Field_A__c, New__c, Field_B__c"
     *   "Old__c"                          -> "New__c"
     *   "Another_Old__c"                  -> unchanged  (not an exact token match)
     */
    @TestVisible
    private static String replaceTokenInList(
            String fieldList,
            String oldToken,
            String newToken) {

        if (String.isBlank(fieldList)) {
            return fieldList;
        }

        // Split on commas, preserving leading/trailing spaces per token
        String[] parts = fieldList.split(',');
        Boolean changed = false;

        for (Integer i = 0; i < parts.size(); i++) {
            String trimmed = parts[i].trim();
            if (trimmed.equalsIgnoreCase(oldToken)) {
                // Preserve original leading/trailing whitespace around the token
                String leading  = parts[i].substringBefore(trimmed);
                String trailing = parts[i].substringAfterLast(trimmed);
                parts[i] = leading + newToken + trailing;
                changed = true;
            }
        }

        return changed ? String.join(parts, ',') : fieldList;
    }

    /**
     * Replaces the value only when it exactly matches oldToken (case-insensitive).
     * Used for single-field values like Filter_Field or Sort_Field.
     */
    @TestVisible
    private static String replaceTokenExact(
            String fieldValue,
            String oldToken,
            String newToken) {

        if (String.isBlank(fieldValue)) {
            return fieldValue;
        }
        return fieldValue.trim().equalsIgnoreCase(oldToken) ? newToken : fieldValue;
    }
}
