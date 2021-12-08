import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:video_player_flutter/models/channel_model.dart';
import 'package:video_player_flutter/models/video_model.dart';
import 'package:video_player_flutter/utilities/keys.dart';

class APIService {
  APIService._instantiate();
  static final APIService instance = APIService._instantiate();

  final String _baseUrl = 'www.googleapis.com';
  String _nextPageToken = '';

  Future<Channel> fetchChannel({String? channelId}) async {
    Map<String, String> parameters = {
      'part': 'snippet, contentDetails, statistics',
      'id': channelId!,
      'key': API_KEY,
    };

    Uri uri = Uri.https(
      _baseUrl,
      '/youtube/v3/channels',
      parameters,
    );

    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/json'
    };

    var response = await http.get(uri, headers: headers);

    // Get Channel
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body)['items'][0];
      Channel channel = Channel.fromMap(data);

      //Fetch first batch of video from uploads playlist
      channel.videos =
          await fetchVideosFromPlaylist(playlistId: channel.uploadPlaylistId);
      return channel;
    } else {
      throw json.decode(response.body)['error']['message'];
    }
  }

  fetchVideosFromPlaylist({String? playlistId}) async {
    Map<String, String> parameters = {
      'part': 'snippet',
      'id': playlistId!,
      'maxResults': '8',
      'pageToken': _nextPageToken,
      'key': API_KEY,
    };

    Uri uri = Uri.https(
      _baseUrl,
      '/youtube/v3/playlistItems',
      parameters,
    );

    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/json'
    };

    // Get Playlist Videos
    var response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      _nextPageToken = data['nextPageToken'] ?? '';
      List<dynamic> videosJson = data['items'];

      //Fetch firsteight videos from uploads playlist
      List<Video> videos = [];
      for (var json in videosJson) {
        videos.add(Video.fromMap(json['snippet']));
      }
      return videos;
    } else {
      throw json.decode(response.body)['error']['message'];
    }
  }
}
