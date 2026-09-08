/// Gemeinsame Schnittstelle für alle Inhaltsmodelle mit Department-Tag
/// (siehe ROADMAP_QuizApp.md Abschnitt 18c). `"general"` = abteilungs-
/// übergreifend; im Lernmodus wird zusätzlich das eigene Department gezeigt,
/// im Wettkampf (1 vs 1, Flottentreffen, lokales Duell) laufen ausschließlich
/// `"general"`-Inhalte. Fehlt das Feld in den Rohdaten, gilt der Inhalt als
/// allgemein.
abstract interface class HasDepartment {
  String get department;
}
