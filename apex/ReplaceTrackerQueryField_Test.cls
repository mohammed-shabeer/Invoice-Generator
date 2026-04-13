/**
 * ReplaceTrackerQueryField_Test
 *
 * Unit tests for ReplaceTrackerQueryField.
 *
 * NOTE: Because sitetracker__Tracker__c is a managed-package object it cannot
 * be inserted in a standard unit test without a Sitetracker license in the org.
 * The private helper methods (replaceTokenInList / replaceTokenExact) are
 * annotated @TestVisible and are fully exercised here without requiring DML.
 *
 * If you deploy this class to an org that does have the Sitetracker package
 * installed and have the ability to insert Tracker records in tests, remove the
 * "// DML disabled in license-free orgs" comments and enable the integration
 * test method below.
 */
@IsTest
private class ReplaceTrackerQueryField_Test {

    // -----------------------------------------------------------------------
    // replaceTokenInList — happy-path
    // -----------------------------------------------------------------------

    @IsTest
    static void replaceTokenInList_replacesExactMatch() {
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            'Field_A__c, Old_Field__c, Field_B__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals(
            'Field_A__c, New_Field__c, Field_B__c',
            result,
            'Exact token in the middle should be replaced.');
    }

    @IsTest
    static void replaceTokenInList_replacesFirstToken() {
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            'Old_Field__c,Field_B__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('New_Field__c,Field_B__c', result);
    }

    @IsTest
    static void replaceTokenInList_replacesLastToken() {
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            'Field_A__c,Old_Field__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('Field_A__c,New_Field__c', result);
    }

    @IsTest
    static void replaceTokenInList_replacesSingleToken() {
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            'Old_Field__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('New_Field__c', result);
    }

    @IsTest
    static void replaceTokenInList_replacesAllOccurrences() {
        // The same field can appear more than once in a query-field list.
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            'Old_Field__c,Field_A__c,Old_Field__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('New_Field__c,Field_A__c,New_Field__c', result);
    }

    @IsTest
    static void replaceTokenInList_isCaseInsensitive() {
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            'old_field__c,Field_A__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('New_Field__c,Field_A__c', result,
            'Replacement must be case-insensitive.');
    }

    @IsTest
    static void replaceTokenInList_preservesWhitespace() {
        // Many Sitetracker tracker field lists use ", " as separator.
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            'Field_A__c, Old_Field__c, Field_B__c',
            'Old_Field__c',
            'New_Field__c');

        // The space before the token should be preserved.
        System.assert(result.contains(', New_Field__c'),
            'Whitespace before token should be preserved.');
    }

    // -----------------------------------------------------------------------
    // replaceTokenInList — no-change cases
    // -----------------------------------------------------------------------

    @IsTest
    static void replaceTokenInList_doesNotMatchSubstring() {
        // "Old_Field__c" must NOT replace inside "Another_Old_Field__c"
        String original = 'Another_Old_Field__c,Field_B__c';
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            original,
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals(original, result,
            'Substring match must not trigger a replacement.');
    }

    @IsTest
    static void replaceTokenInList_noMatchReturnsOriginal() {
        String original = 'Field_A__c,Field_B__c';
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            original,
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals(original, result);
    }

    @IsTest
    static void replaceTokenInList_nullInputReturnsNull() {
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            null,
            'Old_Field__c',
            'New_Field__c');

        System.assertNull(result);
    }

    @IsTest
    static void replaceTokenInList_blankInputReturnsBlank() {
        String result = ReplaceTrackerQueryField.replaceTokenInList(
            '   ',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('   ', result);
    }

    // -----------------------------------------------------------------------
    // replaceTokenExact — happy-path
    // -----------------------------------------------------------------------

    @IsTest
    static void replaceTokenExact_replacesExactValue() {
        String result = ReplaceTrackerQueryField.replaceTokenExact(
            'Old_Field__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('New_Field__c', result);
    }

    @IsTest
    static void replaceTokenExact_isCaseInsensitive() {
        String result = ReplaceTrackerQueryField.replaceTokenExact(
            'old_field__c',
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals('New_Field__c', result);
    }

    // -----------------------------------------------------------------------
    // replaceTokenExact — no-change cases
    // -----------------------------------------------------------------------

    @IsTest
    static void replaceTokenExact_doesNotMatchSubstring() {
        String original = 'Another_Old_Field__c';
        String result = ReplaceTrackerQueryField.replaceTokenExact(
            original,
            'Old_Field__c',
            'New_Field__c');

        System.assertEquals(original, result);
    }

    @IsTest
    static void replaceTokenExact_nullInputReturnsNull() {
        String result = ReplaceTrackerQueryField.replaceTokenExact(
            null,
            'Old_Field__c',
            'New_Field__c');

        System.assertNull(result);
    }

    // -----------------------------------------------------------------------
    // Validation — parameter guards
    // -----------------------------------------------------------------------

    @IsTest
    static void replaceFieldInAllTrackers_throwsOnBlankOldField() {
        Boolean threw = false;
        try {
            ReplaceTrackerQueryField.replaceFieldInAllTrackers('', 'New_Field__c');
        } catch (IllegalArgumentException ex) {
            threw = true;
        }
        System.assert(threw, 'Expected IllegalArgumentException for blank oldFieldApiName.');
    }

    @IsTest
    static void replaceFieldInAllTrackers_throwsOnNullOldField() {
        Boolean threw = false;
        try {
            ReplaceTrackerQueryField.replaceFieldInAllTrackers(null, 'New_Field__c');
        } catch (IllegalArgumentException ex) {
            threw = true;
        }
        System.assert(threw, 'Expected IllegalArgumentException for null oldFieldApiName.');
    }

    @IsTest
    static void replaceFieldInAllTrackers_throwsOnBlankNewField() {
        Boolean threw = false;
        try {
            ReplaceTrackerQueryField.replaceFieldInAllTrackers('Old_Field__c', '');
        } catch (IllegalArgumentException ex) {
            threw = true;
        }
        System.assert(threw, 'Expected IllegalArgumentException for blank newFieldApiName.');
    }

    @IsTest
    static void previewReplacements_throwsOnNullParams() {
        Boolean threw = false;
        try {
            ReplaceTrackerQueryField.previewReplacements(null, null);
        } catch (IllegalArgumentException ex) {
            threw = true;
        }
        System.assert(threw, 'Expected IllegalArgumentException for null params in preview.');
    }

    // -----------------------------------------------------------------------
    // Integration test skeleton (requires Sitetracker package + data access)
    // Uncomment and adapt when running in a full Sitetracker sandbox.
    // -----------------------------------------------------------------------
    /*
    @IsTest
    static void integrationTest_replaceFieldInAllTrackers() {
        // Create test Tracker records
        sitetracker__Tracker__c t1 = new sitetracker__Tracker__c(
            Name = 'Test Tracker 1',
            sitetracker__Query_Fields__c = 'Id, Old_Field__c, Name',
            sitetracker__Filter_Field__c = 'Old_Field__c',
            sitetracker__Sort_Field__c   = 'CreatedDate'
        );
        sitetracker__Tracker__c t2 = new sitetracker__Tracker__c(
            Name = 'Test Tracker 2',
            sitetracker__Query_Fields__c = 'Id, Status__c',
            sitetracker__Filter_Field__c = 'Status__c',
            sitetracker__Sort_Field__c   = null
        );
        insert new List<sitetracker__Tracker__c>{ t1, t2 };

        Test.startTest();
        Integer updated = ReplaceTrackerQueryField.replaceFieldInAllTrackers(
            'Old_Field__c', 'New_Field__c');
        Test.stopTest();

        System.assertEquals(1, updated, 'Only t1 should have been updated.');

        t1 = [SELECT sitetracker__Query_Fields__c, sitetracker__Filter_Field__c,
                      sitetracker__Sort_Field__c
              FROM   sitetracker__Tracker__c WHERE Id = :t1.Id];

        System.assert(t1.sitetracker__Query_Fields__c.contains('New_Field__c'));
        System.assertEquals('New_Field__c', t1.sitetracker__Filter_Field__c);
        System.assertEquals('CreatedDate', t1.sitetracker__Sort_Field__c);

        t2 = [SELECT sitetracker__Query_Fields__c FROM sitetracker__Tracker__c
              WHERE Id = :t2.Id];
        System.assertEquals('Id, Status__c', t2.sitetracker__Query_Fields__c,
            't2 must remain unchanged.');
    }
    */
}
