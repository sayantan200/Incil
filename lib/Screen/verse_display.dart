import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bible/models/bible_data.dart';
import 'package:bible/Services/bible_data_loader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:bible/controller/play_controller.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/shared_pref_constraints.dart';
import 'package:just_audio/just_audio.dart';

class VerseDisplayWidget extends StatefulWidget {
  final String book;
  final int chapter;
  final String content;
  final List<int> maxChapters;
  final String selectedLanguage;

  VerseDisplayWidget({
    required this.book,
    required this.chapter,
    required this.content,
    required this.maxChapters,
    required this.selectedLanguage,
  });

  @override
  _VerseDisplayWidgetState createState() => _VerseDisplayWidgetState();
}

class _VerseDisplayWidgetState extends State<VerseDisplayWidget>
    with TickerProviderStateMixin {
  late final AudioPlayer player;
  late final PlayController playController;
  bool shouldAutoPlay = true;
  //bool isPlaying = false;
  int timeProgress = 0;
  int audioDuration = 0;
  String selectedLanguage = '';

  Widget slider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(getTimeString(timeProgress)),
            Text(getTimeString(audioDuration)),
          ],
        ),
        Slider.adaptive(
          value: timeProgress.toDouble(),
          max: audioDuration.toDouble(),
          onChanged: (value) {
            seekToSec(value.toInt());
          },
        ),
      ],
    );
  }

  void seekToSec(int sec) {
    player.seek(Duration(seconds: sec));
  }

  String getTimeString(int seconds) {
    String minuteString = '${(seconds ~/ 60).toString().padLeft(2, '0')}';
    String secondString = '${(seconds % 60).toString().padLeft(2, '0')}';
    return '$minuteString:$secondString';
  }

  void pauseMusic() async {
    await player.pause();
    playController.isPlayed.value = false;
  }

  void playMusic(String audioUrl) async {
    try {
      await player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      await player.play();
      if (mounted) {
        playController.isPlayed.value = true;
      }
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  late BibleData bibleData;

  Future<void> _loadBibleData() async {
    try {
      bibleData = await BibleDataService().loadBibleData();
    } catch (e) {
      print('Error loading Bible data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading Bible data. Please try again.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    playController = Get.put(PlayController());
    selectedLanguage = widget.selectedLanguage;

    _loadBibleData();

    /*audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        audioDuration = duration.inSeconds;
      });
    });*/

    /*audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        timeProgress = position.inSeconds;
      });
    });*/

    /*player.playerStateStream.listen((PlayerState state) {
      if (state.processingState == ProcessingState.completed) {
        // Audio playback completed, navigate to the next chapter and start playing if needed
        if (shouldAutoPlay) {
          _navigateToNextChapter(context);
        }
      }
    });*/
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Widget _buildVerseDisplayWidget() {
    // Use bibleData to build the actual widget tree
    if (bibleData == null) {
      return CircularProgressIndicator(); // You can replace this with your loading widget
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 38, 83, 130),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextButton(
              onPressed: () {
                _showLanguageSelectionMenu(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 38, 83, 130),
              ),
              child: Text(
                selectedLanguage == 'English' ? 'KJV' : 'İncil',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            SizedBox(width: 65),
            // Book selection
            TextButton(
              onPressed: () {
                _showBookSelectionDialog(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 38, 83,
                    130), // Set the background color to transparent
              ),
              child: Text(
                widget.book,
                style: TextStyle(
                    fontSize: 20.0, // Set the font size as needed
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            SizedBox(width: 8.0), // Add some spacing
            // Chapter selection
            TextButton(
              onPressed: () {
                _showChapterSelectionDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 38, 83,
                    130), // Set the background color to transparent
              ),
              child: Text(
                widget.chapter.toString(),
                style: TextStyle(
                    fontSize: 20.0, // Set the font size as needed
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          // Add the email icon button
          IconButton(
            icon: Icon(Icons.email),
            onPressed: () {
              // Open email with the specified address and subject
              launch(
                'mailto:josephdaniellepalmer@me.com?subject=İncil',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _navigateToPreviousChapter(context);
                } else {
                  _navigateToNextChapter(context);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: SingleChildScrollView(
                  child: Text(
                    widget.content,
                    style: const TextStyle(fontSize: 23.0),
                  ),
                ),
              ),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              minHeight: 58.0,
            ),
            color: Color.fromARGB(255, 38, 83, 130),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _navigateToPreviousChapter(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 38, 83, 130),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                if (getBookIndex() >= 39 &&
                    widget.selectedLanguage == 'Turkish')
                  Obx(
                    () => IconButton(
                      icon: Image.asset(
                        playController.isPlayed.value
                            ? 'assets/images/pausebutton.png'
                            : 'assets/images/playbutton.png',
                        width: 50.0,
                        height: 50.0,
                      ),
                      iconSize: 50.0,
                      onPressed: () async {
                        if (playController.isPlayed.value) {
                          pauseMusic();
                        } else {
                          int bookIndex =
                              bibleData.booksOfBibleTur.indexOf(widget.book);
                          if (bookIndex >= 39 &&
                              widget.selectedLanguage == 'Turkish') {
                            String audioName =
                                bibleData.turAudioName[bookIndex - 39]
                                    [widget.chapter - 1];
                            String audioUrl =
                                'https://incil.online/data/files/$audioName.mp3';

                            playMusic(audioUrl);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Audio not available for this book or language.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                TextButton(
                  onPressed: () => _navigateToNextChapter(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 38, 83, 130),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadBibleData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Build the widget tree once the data is loaded
          return _buildVerseDisplayWidget();
        } else {
          // Show a loading indicator while data is being loaded
          return CircularProgressIndicator();
        }
      },
    );
  }

  // Navigate to the next chapter content
  void _navigateToNextChapter(BuildContext context) async {
    int nextChapter = widget.chapter + 1;

    if (nextChapter > bibleData.chaptersForAll[getBookIndex()]) {
      // If the next chapter exceeds the last chapter of the current book, check for the next book
      int nextBookIndex = getBookIndex() + 1;

      if (nextBookIndex >= 0 &&
          nextBookIndex < bibleData.chaptersForAll.length) {
        String nextBook = widget.selectedLanguage == 'English'
            ? bibleData.booksOfBibleEng[nextBookIndex]
            : bibleData.booksOfBibleTur[nextBookIndex];
        ;
        nextChapter = 1; // Reset to the first chapter of the next book

        print('Book index ${nextBookIndex}');

        _navigateToChapterContent(context, nextBook, nextChapter);
      } else {
        String nextBook = widget.selectedLanguage == 'English'
            ? bibleData.booksOfBibleEng[0]
            : bibleData.booksOfBibleTur[0];

        _navigateToChapterContent(context, nextBook, 1);

        print('Already at the end of the Bible');
      }
    } else {
      // Otherwise, navigate to the next chapter in the current book
      _navigateToChapterContent(context, widget.book, nextChapter);
    }
  }

  // Navigate to a specific chapter content
  void _navigateToChapterContent(
      BuildContext context, String book, int chapter) async {
    String filePath =
        'assets/${widget.selectedLanguage == 'English' ? 'Eng' : 'Tur'}/$book/$book$chapter.txt';
    String chapterContent = await rootBundle.loadString(filePath);
    playController.isPlayed.value = false;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return VerseDisplayWidget(
            book: book,
            chapter: chapter,
            content: chapterContent,
            maxChapters: widget.maxChapters,
            selectedLanguage: widget.selectedLanguage,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child; // Return the child directly for no transition
        },
      ),
    );
  }

  // Navigate to the previous chapter content
  void _navigateToPreviousChapter(BuildContext context) async {
    int previousChapter = widget.chapter - 1;
    int previousBookIndex = getBookIndex();

    ;

    if (previousChapter < 1) {
      print("hello2");
      // If the previous chapter is less than 1, check for the previous book
      previousBookIndex = getBookIndex() - 1;
      print("entered{$previousBookIndex}");

      if (previousBookIndex >= 0) {
        String previousBook = widget.selectedLanguage == 'English'
            ? bibleData.booksOfBibleEng[previousBookIndex]
            : bibleData.booksOfBibleTur[previousBookIndex];
        int lastChapterOfPreviousBook =
            bibleData.chaptersForAll[previousBookIndex];
        print("hello 1 {$lastChapterOfPreviousBook}");

        _navigateToChapterContent(
            context, previousBook, lastChapterOfPreviousBook);
      } else {
        print('Already at the beginning of the Bible ${getBookIndex()}');
        String nextBook = widget.selectedLanguage == 'English'
            ? bibleData.booksOfBibleEng[65]
            : bibleData.booksOfBibleTur[65];

        _navigateToChapterContent(context, nextBook, 22);
      }
    } else {
      print(
          'Navigating to previous chapter. Current Book Index: ${getBookIndex()}  and ');
      // Otherwise, navigate to the previous chapter in the current book

      _navigateToChapterContent(context, widget.book, previousChapter);
    }
  }

  void playMusicForChapter(String book, int chapter) {
    // Update the audio URL based on the new chapter
    int bookIndex = getBookIndex();
    if (bookIndex >= 39 && widget.selectedLanguage == 'Turkish') {
      String audioName = bibleData.turAudioName[bookIndex - 39][widget.chapter];
      String audioUrl = 'https://incil.online/data/files/$audioName.mp3';
      print("Entered in playMusicForChapter $audioUrl");
      playMusic(audioUrl);
    }
  }

  int getBookIndex() {
    // Calculate the current book index
    int bookIndex = widget.selectedLanguage == 'English'
        ? bibleData.booksOfBibleEng.indexOf(widget.book)
        : bibleData.booksOfBibleTur.indexOf(widget.book);

    return bookIndex;
  }

  // Show book selection dialog
  Future<void> _showBookSelectionDialog(BuildContext context) async {
    String? selectedBook = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              selectedLanguage == 'English'
                  ? 'Book Choices'
                  : 'Kitap Seçenekleri',
            ),
          ),
          contentPadding:
              EdgeInsets.only(top: 20.0), // Adjust the top padding as needed
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.75,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (String book in widget.selectedLanguage == 'English'
                      ? bibleData.booksOfBibleEng
                      : bibleData.booksOfBibleTur)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, book);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ),
                      ),
                      child: Text(
                        book,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    print("$selectedBook");

    await sharedPref.setChapterName(selectedBook!);
    selectedBook = await sharedPref.getChapterName();

    await sharedPref.setChapterNumber(1);
    int selectedNumber = await sharedPref.getChapterNumber() ?? 1;

    if (selectedBook != null) {
      _navigateToChapterContent(context, selectedBook, 1);
    }
  }

// Show chapter selection dialog
  Future<void> _showChapterSelectionDialog(BuildContext context) async {
    int? selectedChapter = await showDialog(
      context: context,
      builder: (BuildContext context) {
        int bookIndex = widget.selectedLanguage == 'English'
            ? bibleData.booksOfBibleEng.indexOf(widget.book)
            : bibleData.booksOfBibleTur.indexOf(widget.book);

        return AlertDialog(
          title: Center(
            child: Text(
              selectedLanguage == 'English' ? 'Chapters' : 'Bölümler',
            ),
          ),
          contentPadding: EdgeInsets.only(top: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width *
                0.05, // Set the width as needed
            height: MediaQuery.of(context).size.height *
                0.73, // Set the height as needed
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 1; i <= bibleData.chaptersForAll[bookIndex]; i++)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, i);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ),
                      ),
                      child: Text(
                        i.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    await sharedPref.setChapterNumber(selectedChapter!);
    selectedChapter = await sharedPref.getChapterNumber();

    if (selectedChapter != null) {
      _navigateToChapterContent(context, widget.book, selectedChapter);
    }
  }

  void _showLanguageSelectionMenu(BuildContext context) async {
    String? language = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(0, 80, 0, 0),
      items: [
        PopupMenuItem<String>(
          value: 'Turkish',
          child: Text(
            'Türkçe (İncil)',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),
        PopupMenuItem<String>(
          value: 'English',
          child: Text(
            'English (King \nJames Version)',
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    String books = language == 'English'
        ? bibleData.booksOfBibleEng[getBookIndex()]
        : bibleData.booksOfBibleTur[getBookIndex()];
    String filePath =
        'assets/${language == 'English' ? 'Eng' : 'Tur'}/$books/$books${widget.chapter}.txt';
    String chapterContent = await rootBundle.loadString(filePath);
    print(
        "language is $language , book is ${books} , chapter is ${widget.chapter} , book index ${getBookIndex()} , book in english ${bibleData.booksOfBibleEng[getBookIndex()]},\n file path $filePath");
    if (language != null) {
      setState(() {
        selectedLanguage = language;
      });
      // Get the current route
      Route<dynamic>? route = ModalRoute.of(context);

      AppConstraints.chapterNumberVal = await sharedPref.getChapterNumber();
      AppConstraints.chapterNameVal = await sharedPref.getChapterName();
      AppConstraints.languageVal = await sharedPref.getLanguage();

      // Check if the route is a MaterialPageRoute and has settings

      // Reload the page with the selected language and updated book
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerseDisplayWidget(
            book: books,
            chapter: widget.chapter,
            content: chapterContent,
            maxChapters: widget.maxChapters,
            selectedLanguage: language,
          ),
        ),
      );
    }
  }
}
