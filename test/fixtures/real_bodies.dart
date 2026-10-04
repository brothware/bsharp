import 'dart:io';

const _bodiesDirectory = 'test/fixtures/bodies';

const realAnnouncementLink =
    'https://mobireg.freshdesk.com/a/solutions/articles/11000128714';

String loadBody(String name) {
  return File('$_bodiesDirectory/$name').readAsStringSync().trimRight();
}

String get realAnnouncementHtml => loadBody('announcement.html');

List<String> get realAnnouncementLines =>
    loadBody('announcement_lines.txt').split('\n');

String get realLibraryPreview => loadBody('library_preview.txt');

String get libraryMessageHtml => loadBody('library_message.html');
