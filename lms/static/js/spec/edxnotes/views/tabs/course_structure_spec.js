define([
    'jquery', 'underscore', 'js/common_helpers/template_helpers', 'js/spec/edxnotes/helpers',
    'js/edxnotes/collections/notes', 'js/edxnotes/collections/tabs',
    'js/edxnotes/views/tabs/course_structure', 'js/spec/edxnotes/custom_matchers',
    'jasmine-jquery'
], function(
    $, _, TemplateHelpers, Helpers, NotesCollection, TabsCollection, CourseStructureView,
    customMatchers
) {
    'use strict';
    describe('EdxNotes CourseStructureView', function() {
        var notes = Helpers.getDefaultNotes(),
            getView, getText;

        getText = function (selector) {
            return $(selector).map(function () {
                return _.trim($(this).text());
            }).toArray();
        };

        getView = function (collection, tabsCollection, options) {
            var view;

            options = _.defaults(options || {}, {
                el: $('.wrapper-student-notes'),
                collection: collection,
                tabsCollection: tabsCollection,
            });

            view = new CourseStructureView(options);
            tabsCollection.at(0).activate();

            return view;
        };

        beforeEach(function () {
            customMatchers(this);
            loadFixtures('js/fixtures/edxnotes/edxnotes.html');
            TemplateHelpers.installTemplates([
                'templates/edxnotes/note-item', 'templates/edxnotes/tab-item'
            ]);

            this.collection = new NotesCollection(notes);
            this.tabsCollection = new TabsCollection();
        });

        it('displays a tab and content with proper data and order', function () {
            var view = getView(this.collection, this.tabsCollection),
                chapters = getText('.course-title'),
                sections = getText('.course-subtitle'),
                notes = getText('.note-excerpt-p');

            expect(this.tabsCollection).toHaveLength(1);
            expect(this.tabsCollection.at(0).toJSON()).toEqual({
                name: 'Location in Course',
                identifier: 'view-course-structure',
                icon: 'fa fa-list-ul',
                is_active: true,
                is_closable: false,
                view: 'Location in Course'
            });
            expect(view.$('#structure-panel')).toExist();
            expect(chapters).toEqual(['First Chapter', 'Second Chapter']);
            expect(sections).toEqual(['First Section', 'Second Section', 'Third Section']);
            expect(notes).toEqual(['Note 1', 'Note 2', 'Note 3', 'Note 4', 'Note 5']);
        });
    });
});
