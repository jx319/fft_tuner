# FFT-Stimmgerät

[Downloads](https://github.com/jx319/fft_tuner/releases)

Dieses Projekt entstand im Rahmen eines W-Seminars zum Leitfach Physik.
Es beinhaltet eine Android-App, die mithilfe des FFT-Algorithmus ein
Schallspektrum erstellt und daraus den gespielten Ton ermittelt, sodass
das Programm zum Stimmen von Instrumenten verwendet werden kann.

Der relevante Code befindet sich vor allem im Verzeichnis `lib/`.
Die meisten anderen Dateien werden von Flutter automatisch generiert.

Zum Kompilieren des Codes für Android kann nach Installation der SDKs für Flutter und Android
der Befehl `flutter build apk --release` in der Kommandozeile genutzt werden.
