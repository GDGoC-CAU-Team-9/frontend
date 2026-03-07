import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/team_model.dart';
import 'dart:developer' as developer;

class TeamRepository {
  final Dio _dio;

  TeamRepository(this._dio);

  // 1. 팀 생성
  Future<TeamModel> createTeam(String teamName) async {
    try {
      final response = await _dio.post('/teams', data: {'teamName': teamName});
      return TeamModel.fromJson(response.data['result']);
    } catch (e) {
      developer.log('Error creating team: $e', name: 'TeamRepository');
      rethrow;
    }
  }

  // 2. 내 팀 목록 조회 (페이징)
  Future<TeamPageResult> getMyTeams(int pageNumber) async {
    try {
      final response = await _dio.get(
        '/teams',
        queryParameters: {'pageNumber': pageNumber},
      );
      return TeamPageResult.fromJson(response.data['result']);
    } catch (e) {
      developer.log('Error fetching teams: $e', name: 'TeamRepository');
      rethrow;
    }
  }

  // 3. 팀 상세 조회 (팀멤버 ID로 조회, 멤버 정보 포함)
  Future<TeamModel> getTeamDetail(int teamMemberId) async {
    try {
      final response = await _dio.get('/teams/$teamMemberId');
      return TeamModel.fromJson(response.data['result']);
    } catch (e) {
      developer.log('Error fetching team detail: $e', name: 'TeamRepository');
      rethrow;
    }
  }

  // 4. 팀 참여 (초대 등)
  Future<TeamModel> joinTeam({
    required String teamMemberEmail,
    required int teamMemberId,
    required String teamName,
  }) async {
    try {
      final response = await _dio.post(
        '/teams/join',
        data: {
          'teamMemberEmail': teamMemberEmail,
          'teamMemberId': teamMemberId,
          'teamName': teamName,
        },
      );
      return TeamModel.fromJson(response.data['result']);
    } catch (e) {
      developer.log('Error joining team: $e', name: 'TeamRepository');
      rethrow;
    }
  }

  // 5. 팀명 변경
  Future<TeamModel> renameTeam(int teamMemberId, String newTeamName) async {
    try {
      final response = await _dio.patch(
        '/teams/members/$teamMemberId',
        data: {'teamName': newTeamName},
      );
      return TeamModel.fromJson(response.data['result']);
    } catch (e) {
      developer.log('Error renaming team: $e', name: 'TeamRepository');
      rethrow;
    }
  }

  // 6. 팀 나가기 (탈퇴)
  Future<void> exitTeam(int teamMemberId) async {
    try {
      await _dio.delete('/teams/members/$teamMemberId');
    } catch (e) {
      developer.log('Error exiting team: $e', name: 'TeamRepository');
      rethrow;
    }
  }
}

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TeamRepository(dio);
});
