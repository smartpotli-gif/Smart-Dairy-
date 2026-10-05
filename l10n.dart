import 'store.dart';

const _en = {
  'आज': 'Today', 'कॅलेंडर': 'Calendar', 'कामं': 'Tasks', 'नोट्स': 'Notes', 'अधिक': 'More',
  'चुकलेलं': 'Missed', 'आता पुढे': 'Up next', 'पुढे येणारं': 'Coming up', 'झालेलं': 'Done',
  'मीटिंग': 'Meeting', 'नोट': 'Note', 'Summary': 'Summary', 'ट्रिप': 'Trip', 'AI': 'AI',
  'शोधा…': 'Search…', 'Settings': 'Settings', 'Contacts': 'Contacts', 'Trips': 'Trips',
  'बाकी': 'Pending', 'पूर्ण': 'Completed', 'आज पुढे काही नाही.': 'Nothing more today.',
  'उदा. आज 2 वाजता मीटिंग आहे': 'e.g. meeting today 2 pm',
};

String tr(String mr) => Store.I.s.lang == 'en' ? (_en[mr] ?? mr) : mr;
