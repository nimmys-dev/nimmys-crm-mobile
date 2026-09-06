import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nimmys_crm/core/auth/session_expiry_handler.dart';
import 'package:nimmys_crm/data/model/result.dart';
import 'package:nimmys_crm/data/storage/secured_shared_preferences.dart';
import 'package:nimmys_crm/service/hasInternet/has_internet_connection.dart';
import 'package:nimmys_crm/utils/app_string.dart';
import 'package:nimmys_crm/utils/constant_variables.dart';
import 'package:nimmys_crm/utils/custom_log.dart';

class ApiService {
  final Duration _timeout = const Duration(
    seconds: 30,
  ); // General timeout for all requests
  final Dio _dio;
  final SecuredSharedPreferences _secureSharedPrefs;

  ApiService(this._dio, this._secureSharedPrefs) {
    _dio.options.connectTimeout = _timeout;
    _dio.options.receiveTimeout = _timeout;
  }

  // Header
  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final headers = <String, String>{
      'Content-Type': isMultipart ? 'multipart/form-data' : 'application/json',
      'Accept': 'application/json',
    };

    // Bearer wins when the user is signed in: the CRM API authenticates with a
    // Sanctum token, and login itself is the one call that legitimately has none.
    final bearerToken = await _secureSharedPrefs.get(
      AppString.sessionKey.userToken,
    );
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
      return headers;
    }

    // Basic auth is optional — the CRM API is not behind it, so empty creds mean
    // "send no Authorization header" rather than a failure.
    final username = dotenv.env["API_BASIC_AUTH_USERNAME"];
    final password = dotenv.env["API_BASIC_AUTH_PASSWORD"];
    if (username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty) {
      headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('$username:$password'))}';
    }

    return headers;
  }

  // Clear Cache
  //
  // Nothing is cached at the moment: the response cache was `dio_http_cache`,
  // which is dio 4 only and cannot be resolved alongside dio 5. Reinstate it
  // with `dio_cache_interceptor` — the maintained dio 5 equivalent — and fill
  // this in, rather than pinning dio back to 4.
  Future<void> clearCache() async {
    CustomLog.info(this, "No response cache configured — nothing to clear");
  }

  // Get
  Future<Result<dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParams,
    bool forceRefresh = false,
    CancelToken? cancelToken,
  }) async {
    CustomLog.debug(
      this,
      "\nMethod : Get, \nURL : $url,n,QueryParams : $queryParams",
    );
    try {
      if (HasInternetConnection.isInternet != true) {
        return Error(InternetNetworkError());
      }
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(
          headers: await _getHeaders(),
          receiveTimeout: _timeout,
        ),
      );
      return _handleBodyResponse(response);
    } on DioException catch (dioError) {
      return _handleDioError(dioError);
    } catch (exception) {
      CustomLog.error(this, "Generic HTTP call error", exception);
      return Error(GenericError());
    }
  }

  // Post
  Future<Result<dynamic>> post(
    String url, {
    dynamic body,
    Map<String, dynamic>? queryParams,
  }) async {
    Object prettyBodyString;
    if (queryParams != null) {
      prettyBodyString = const JsonEncoder.withIndent(
        '  ',
      ).convert(queryParams);
    } else {
      prettyBodyString = const JsonEncoder.withIndent('  ').convert(body);
    }
    CustomLog.debug(
      this,
      "\nMethod: Post \nURL: $url \nRequest: $prettyBodyString",
    );
    try {
      if (!HasInternetConnection.isInternet) {
        return Error(InternetNetworkError());
      }
      final response = await _dio.post(
        url,
        data: body,
        queryParameters: queryParams,
        options: Options(
          headers: await _getHeaders(),
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      return _handleBodyResponse(response);
    } on DioException catch (dioError) {
      return _handleDioError(dioError);
    } catch (exception) {
      CustomLog.error(this, "Generic HTTP call error", exception);
      return Error(GenericError());
    }
  }

  // Put
  Future<Result<dynamic>> put(String url, {dynamic body}) async {
    final Object prettyBodyString = const JsonEncoder.withIndent(
      '  ',
    ).convert(body);
    CustomLog.debug(
      this,
      "\nMethod: Put \nURL: $url \nRequest: $prettyBodyString",
    );
    try {
      if (!HasInternetConnection.isInternet) {
        return Error(InternetNetworkError());
      }
      final response = await _dio.put(
        url,
        data: body,
        options: Options(
          headers: await _getHeaders(),
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      return _handleBodyResponse(response);
    } on DioException catch (dioError) {
      return _handleDioError(dioError);
    } catch (exception) {
      CustomLog.error(this, "Generic PUT HTTP call error", exception);
      return Error(GenericError());
    }
  }

  // Delete
  Future<Result<dynamic>> delete(String url) async {
    CustomLog.debug(this, "Method: Delete, URL: $url");
    try {
      if (!HasInternetConnection.isInternet) {
        return Error(InternetNetworkError());
      }

      final response = await _dio.delete(
        url,
        options: Options(
          headers: await _getHeaders(),
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      return _handleBodyResponse(response);
    } on DioException catch (dioError) {
      return _handleDioError(dioError);
    } catch (exception) {
      CustomLog.error(this, "Generic HTTP call error", exception);
      return Error(GenericError());
    }
  }

  // Multi parts
  Future<Result<dynamic>> multipart(
    String url,
    dynamic files, {
    Map<String, String>? fields,
    String? pathName,
  }) async {
    try {
      if (!HasInternetConnection.isInternet) {
        return Error(InternetNetworkError());
      }

      final prettyFieldsString = const JsonEncoder.withIndent(
        '  ',
      ).convert(fields);
      CustomLog.debug(
        this,
        "\nMethod : Multipart \nURL : $url \nPath name : $pathName \nFiles : $files \nFields : $prettyFieldsString",
      );

      FormData formData = FormData();

      // Handling file upload (single or multiple)
      if (files != null) {
        if (files is List<File>) {
          for (var file in files) {
            if (await file.exists()) {
              formData.files.add(
                MapEntry(
                  pathName ?? "file",
                  await MultipartFile.fromFile(file.path),
                ),
              );
            } else {
              CustomLog.debug(this, "File not found: ${file.path}");
            }
          }
        } else if (files is File) {
          if (await files.exists()) {
            formData.files.add(
              MapEntry(
                pathName ?? "file",
                await MultipartFile.fromFile(files.path),
              ),
            );
          } else {
            CustomLog.debug(this, "File not found: ${files.path}");
          }
        } else {
          return Error(
            ErrorWithMessage(message: "Invalid file type provided."),
          );
        }
      }

      // Adding extra form fields if provided
      if (fields != null && fields.isNotEmpty) {
        formData.fields.addAll(fields.entries);
      }

      debugPrint("Form Data : ${formData.fields.toString()}");
      debugPrint("Form Data files : ${formData.files.toString()}");

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: await _getHeaders(isMultipart: true),
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );

      return _handleBodyResponse(response);
    } on DioException catch (dioError) {
      return _handleDioError(dioError);
    } catch (exception) {
      CustomLog.error(this, "HTTP call error during multipart", exception);
      return Error(ErrorWithMessage(message: "$exception"));
    }
  }

  // Handle Body Response
  Result<dynamic> _handleBodyResponse(Response response) {
    final prettyBodyString = const JsonEncoder.withIndent(
      '  ',
    ).convert(response.data);
    CustomLog.debug(
      this,
      "\nResponse status code: ${response.statusCode}, \nResponse data: $prettyBodyString",
    );
    try {
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Success(response.data);
      } else {
        return _handleHttpError(response);
      }
    } on Exception catch (e) {
      CustomLog.error(this, "Error decoding data response: $e", null);
      return Error(GenericError());
    }
  }

  // Handel HTTP Error
  //
  // Every non-2xx in the app funnels through here — `_handleBodyResponse` sends
  // the ones Dio lets through, `_handleDioError` sends the ones it throws on —
  // which makes it the one place that can notice the token has stopped working.
  // SessionExpiryHandler decides whether the failure actually ends the session;
  // a 404 or a validation error is not an expiry and is handed back untouched.
  Result<dynamic> _handleHttpError(Response? response) {
    final ErrorType error = _errorForResponse(response);
    SessionExpiryHandler.notify(
      error,
      requestPath: response?.requestOptions.uri.path,
    );
    return Error(error);
  }

  // Status Code to Error Type
  ErrorType _errorForResponse(Response? response) {
    switch (response?.statusCode) {
      case 400:
      // 422 is the CRM API's validation failure — the body names the offending
      // field, which is far more useful than a generic error.
      case 422:
        return ErrorWithMessage.fromApiResponse(response?.data);
      case 401:
        return UnauthenticatedError();
      // 403 is the API's own RBAC talking: the token is fine, the role is not
      // allowed. The client guards routes too, but the server is the authority
      // and this is what happens when the two disagree.
      case 403:
        return ForbiddenError();
      case 404:
        return NotFoundError();
      case 409:
        return ConflictError();
      case 498:
        return InvalidTokenError();
      case 500:
        return InternalServerError();
      default:
        log("Unexpected status code: ${response?.statusCode}");
        return GenericError();
    }
  }

  // Handle Dio Error
  Result<dynamic> _handleDioError(DioException error) {
    CustomLog.error(
      this,
      "DIO HTTP call error,Status Code : ${error.response?.statusCode} response : ${error.response}",
      error,
    );
    switch (error.type) {
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Error(NetworkTimeoutError());
      default:
        return Error(ErrorWithMessage(message: error.response?.data));
    }
  }

  // Json to Query Params
  String jsonToQueryParams(Map<String, dynamic> json) {
    String stringQueryParams = "";
    try {
      return json.entries
          .map((e) {
            final key = Uri.encodeComponent(e.key);
            final value = Uri.decodeComponent(e.value.toString());
            stringQueryParams = '$key=$value';
            return stringQueryParams;
          })
          .join('&');
    } catch (e) {
      CustomLog.error(
        this,
        "QueryParams : $stringQueryParams,\nRun type : ${stringQueryParams.runtimeType}",
        e,
      );
      return stringQueryParams;
    }
  }

  String decodeQueryParams(String queryString) {
    return Uri.splitQueryString(queryString).entries
        .map((e) {
          final key = e.key;
          final value = Uri.decodeComponent(
            e.value,
          ); // Decode percent-encoded values
          return '$key = $value';
        })
        .join('\n');
  }

  // Get Response Result Status
  Future<Result<T>> getResponseStatus<T>(
    dynamic result,
    T Function(dynamic) fromJson,
  ) async {
    if (result[STATUS] == true) {
      final data = fromJson(result);
      return Success(data);
    } else if (result[STATUS] == false) {
      return Error(ErrorWithMessage(message: result[MESSAGE]));
    } else {
      return Error(ResponseStatusFailed());
    }
  }
}
