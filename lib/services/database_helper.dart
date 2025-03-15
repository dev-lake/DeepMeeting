import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/meeting_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meetings.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meetings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        attendees TEXT NOT NULL,
        meetingTime TEXT NOT NULL,
        duration TEXT NOT NULL,
        meetingEndTime TEXT NOT NULL,
        recorder TEXT NOT NULL,
        reviewer TEXT NOT NULL,
        audioPath TEXT NOT NULL,
        content TEXT NOT NULL,
        transcription TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE meetings ADD COLUMN transcription TEXT DEFAULT ""');
    }
  }

  Future<String> _copyAudioFile(String originalPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = basename(originalPath);
    final String newPath = join(directory.path, 'meeting_audios', fileName);

    // 确保目标目录存在
    final audioDir = Directory(join(directory.path, 'meeting_audios'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    // 复制文件
    await File(originalPath).copy(newPath);
    return newPath;
  }

  Future<int> insertMeeting(MeetingRecord meeting) async {
    final db = await instance.database;

    // 复制音频文件到应用目录
    final newAudioPath = await _copyAudioFile(meeting.audioPath);
    final meetingWithNewPath = MeetingRecord(
      title: meeting.title,
      attendees: meeting.attendees,
      meetingTime: meeting.meetingTime,
      duration: meeting.duration,
      meetingEndTime: meeting.meetingEndTime,
      recorder: meeting.recorder,
      reviewer: meeting.reviewer,
      audioPath: newAudioPath,
      content: meeting.content,
      transcription: meeting.transcription,
    );

    return await db.insert('meetings', meetingWithNewPath.toMap());
  }

  Future<List<MeetingRecord>> getAllMeetings() async {
    final db = await instance.database;
    final result = await db.query('meetings', orderBy: 'createdAt DESC');
    return result.map((json) => MeetingRecord.fromMap(json)).toList();
  }

  Future<MeetingRecord?> getMeeting(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'meetings',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return MeetingRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteMeeting(int id) async {
    final db = await instance.database;

    // 获取会议记录
    final meeting = await getMeeting(id);
    if (meeting != null) {
      // 删除关联的音频文件
      final audioFile = File(meeting.audioPath);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }

    return await db.delete(
      'meetings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
