library FacebookAPI;

import 'dart:html';
import 'dart:js';
import 'dart:async';

class FacebookAPI {
  
  static String getPictureURL_fromUserID(String userID) {
    if ( userID == null ) return null ;
    return "http://graph.facebook.com/"+userID+"/picture" ;
  }
  
  static Element headElement ;
  
  static Element getHeadElement() {
    if (headElement == null) {
      List<Node> list = document.getElementsByTagName('head') ;
      headElement = list[0] ;
    }
    
    return headElement ; 
  }
  
  static bool loadJS(String url , [ void onSucess() , void onError() ]) {
    Element head = getHeadElement() ;
    
    ScriptElement script = new ScriptElement() ;
    
    script.src = url ;
    script.type = "text/javascript";
    
    script.onLoad.listen( (e) => onSucess() , onError: (e) => onError() , cancelOnError: true) ;
    
    head.children.add(script) ;
    
    return true ;
  }
  
  static jsEval(String code) {
    
    return context.callMethod('eval', [code]) ;
    
  }
  
  static jsEval_PARAMS(String code, List PARAMS) {
    _inject_jsCall() ;
    
    JsObject obj = new JsObject.jsify(PARAMS) ;
    
    return context.callMethod('__FacebookAPI__jsEval_PARAMS', [code , obj]) ;
    
  }
  
  static String toJSON_String(obj) {
    String ret = jsEval_PARAMS(' JSON.stringify(PARAMS[0]) ; ', [obj]);
    return ret ;
  }
  
  static bool _inject_jsCall_Loaded = false ; 
  
  static void _inject_jsCall() {
    
    if ( _inject_jsCall_Loaded ) return ;
    
    jsEval("""
    
      __FacebookAPI__jsCall = function(functName , params) {
          var funct = eval(functName) ;

          switch( params.length ) {
              case  0: return funct() ; break ;
              case  1: return funct( params[0] ) ; break ;
              case  2: return funct( params[0], params[1] ) ; break ;
              case  3: return funct( params[0], params[1], params[2] ) ; break ;
              case  4: return funct( params[0], params[1], params[2], params[3] ) ; break ;
              case  5: return funct( params[0], params[1], params[2], params[3], params[4] ) ; break ;
              case  6: return funct( params[0], params[1], params[2], params[3], params[4], params[5] ) ; break ;
              case  7: return funct( params[0], params[1], params[2], params[3], params[4], params[5], params[6] ) ; break ;
              case  8: return funct( params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7] ) ; break ;
              case  9: return funct( params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8] ) ; break ;
              case 10: return funct( params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9] ) ; break ;
              default: return funct( params ) ; break ;
          }
      } ;

      __FacebookAPI__jsEval_PARAMS = function(CODE , PARAMS) {
          return eval(CODE) ;
      } ;

    """) ;
    
    _inject_jsCall_Loaded = true ;
    
  }
  
  static jsCall(String function, [ List args ]) {
    
    _inject_jsCall() ;
    
    JsObject obj = new JsObject.jsify(args) ;
        
    context.callMethod('__FacebookAPI__jsCall' , [ function , obj ]) ;
    
  }
  
  //////////////////////////////////////////////////////////////
  
  String _appID ;
  String _channelURL ;
  
  static FacebookAPI _singletonInstance ; 
  
  factory FacebookAPI(String appID, { String channelURL }) {
    
    if (_singletonInstance == null) {
      _singletonInstance = new FacebookAPI._singleton(appID, channelURL: channelURL) ;
      return _singletonInstance ;
    }
    else {
      
      if ( _singletonInstance.appID != appID ) throw new StateError('FacebookAPI already instantiated with different appID: previous: ${ _singletonInstance.appID } != param: $appID') ;
      
      if ( _singletonInstance.channelURL != channelURL ) throw new StateError('FacebookAPI already instantiated with different channelURL: previous: ${ _singletonInstance.channelURL } != param: $channelURL') ;
    
      return _singletonInstance ;
    }
    
  }
  
  FacebookAPI._singleton(String appID, { String channelURL }) {
    this._appID = appID ;
    
    this._channelURL = channelURL ;
    
    _load() ;
  }
  
  String get appID => _appID ;
  
  String get channelURL => _channelURL ;
  
  String get pictureURL => getPictureURL_fromUserID(currentUserID) ;
  
  static String _createAuthResponse(String accessToken, { String userID, String expires } ) {
    String authResponse = "{"
                          "'accessToken':'$accessToken'"
                          "${ userID != null && userID.isNotEmpty ? " , 'userID':'$userID'" : "" } "
                          "${ expires != null && expires.isNotEmpty ? " , 'expiresIn':$expires" : "" } "
                          "}" ;
    
    return authResponse ;
  }
  
  String _parseAuthResponseFromCurrentLocation() {
    String urlHash = window.location.hash ;
    
    if ( urlHash != null && urlHash.contains('access_token') && urlHash.contains('expires_in') ) {
      String accessToken = urlHash.split("access_token=")[1].split("&")[0] ;
      String expiresIn = urlHash.split("expires_in=")[1].split("&")[0] ;
      
      return _createAuthResponse(accessToken, expires: expiresIn) ;
    }
    
    return null ;
  }
  
  bool _injected = false ;
  void _injectJS() {
    
    if (_injected) return ;
    _injected = true ;
    
    var divFBRoot = querySelector("#fb-root") ;
    
    if (divFBRoot == null) {
      divFBRoot = new Element.div() ;
      divFBRoot.id = "fb-root" ;
      Element head = getHeadElement() ;  
      head.children.add(divFBRoot) ;
    }
    
    String urlHash = window.location.hash ;
    
    String authResponse = _parseAuthResponseFromCurrentLocation() ;
    
    jsEval("""

      __FacebookAPI__initCalled = false ;

      window.fbAsyncInit = function() {

        if (!__FacebookAPI__initCalled) {
          FB.init({
          'appId'     : '$_appID' ,  
          'status'    : true,
          'cookie'    : true,
          'xfbml'     : true,
          'version'   : 'v2.0',
          'oauth'     : true
          ${ authResponse != null ? ", 'authResponse': '$authResponse' " : "" }
          ${ _channelURL != null ? ", 'channelUrl': '$_channelURL' " : "" }
          }) ;
  
          __FacebookAPI__initCalled = true ;
        }

      };

    """) ;
    
    loadJS("//connect.facebook.net/en_US/all.js", _notifyFBLoaded ) ;
    
  }

  bool _loaded = false ;
  
  void _load() {
    
    if (_loaded) return ;
    
    _injectJS() ;
    
    getLoginStatus(null) ;
    
  }
  
  void _notifyFBLoaded() {
    _loaded = true ;
    
    _flushExecutedWhenLoaded() ;
  }
  
  List<Function> _whenLoadFunctionsQueue = [] ;
  
  void _flushExecutedWhenLoaded() {
    
    _whenLoadFunctionsQueue.any( (f) { f() ; return false ;} ) ;
    
    _whenLoadFunctionsQueue = [] ;
    
  }
  
  void _executedWhenLoaded( Function funct() ) {
    
    if (_loaded) {
      funct() ;
      return ;
    }
    
    _whenLoadFunctionsQueue.add(funct) ;
    
  }
  
  bool _tryFbInitCalled = false ;
  
  void _tryFbInit() {
  
    if (_tryFbInitCalled) return ;
    _tryFbInitCalled = true ;
    
    String authResponse = _parseAuthResponseFromCurrentLocation() ;
    
    jsEval("""

        if ( !__FacebookAPI__initCalled ) {
          FB.init({
          'appId'     : '$_appID' ,  
          'status'    : true,
          'cookie'    : true,
          'xfbml'     : true,
          'oauth'     : true
          ${ authResponse != null ? ", 'authResponse': '$authResponse' " : "" }
          ${ _channelURL != null ? ", 'channelUrl': '$_channelURL' " : "" }
          }) ;
  
          __FacebookAPI__initCalled = true ;

        }

    """) ;
    
    
    
  }
  
  ////////////////////////////////////////////
  
  void login( void functResponse(FacebookLoginStatus response) , { String scope } ) {
    if (_loaded) {
      _login(functResponse, scope: scope) ;
    }
    else {
      _executedWhenLoaded( () {
        _login(functResponse, scope: scope) ;  
      } ) ;
    }
  }
  
  void _login( void functResponse(FacebookLoginStatus response) , { String scope } ) {
    _tryFbInit() ;
    
    Map loginParams = {} ;
    
    if (scope != null && scope.isNotEmpty) {
      loginParams['scope'] = scope ;
    }
    
    Function functWrapper = (JsObject response) {
      FacebookLoginStatus loginStatus = _catch_LoginStatus(response, true) ;
      if (functResponse != null) functResponse(loginStatus) ;
    } ;
    
    jsCall('FB.login', [ functWrapper , loginParams ]) ;
        
  }
  
  void getLoginStatus( void functResponse(FacebookLoginStatus response) , [ bool reuseCached ] ) {
    if (_loaded) {
      _getLoginStatus(functResponse) ;
    }
    else {
      _executedWhenLoaded( () {
        _getLoginStatus(functResponse) ;  
      } ) ;
    }
  }
  
  void _getLoginStatus( void functResponse(FacebookLoginStatus response) , [ bool reuseCached ] ) {
    _tryFbInit() ;
    
    if ( reuseCached == true && _lastLoginStatus != null ) {
      functResponse(_lastLoginStatus) ;
      return ;
    }
    
    Function functWrapper = (JsObject response) {
      FacebookLoginStatus loginStatus = _catch_LoginStatus(response, false) ;
      if (functResponse != null) functResponse(loginStatus) ;
    } ;
    
    jsCall('FB.getLoginStatus', [ functWrapper ]) ;
  }
  

  void logout( void functResponse(FacebookLoginStatus response) ) {
    if (_loaded) {
      _logout(functResponse) ;
    }
    else {
      _executedWhenLoaded( () {
        _logout(functResponse) ;  
      } ) ;
    }
  }
  
  void _logout( void functResponse(FacebookLoginStatus response) ) {
    _tryFbInit() ;
    
    Function functWrapper = (JsObject response) {
      FacebookLoginStatus loginStatus = _catch_Logout(response) ;
      if (functResponse != null) functResponse(loginStatus) ;
    } ;
    
    jsCall('FB.logout', [ functWrapper ]) ;
  }
  
  void api(String path , void functResponse(JsObject response) , [ params , String method ] ) {
    if (_loaded) {
      _api(path, functResponse, params, method) ;
    }
    else {
      _executedWhenLoaded( () {
        _api(path, functResponse, params, method) ;  
      } ) ;
    }
  }
  
  void _api(String path , void functResponse(JsObject response) , [ params , String method ] ) {
    
    if ( params != null ) {
      
      if (method != null) {
        jsCall('FB.api', [ path, method, params, functResponse ]) ;  
      }
      else {
        jsCall('FB.api', [ path, params, functResponse ]) ;
      }
      
    }
    else {
      jsCall('FB.api', [ path, functResponse ]) ;
    }
  }
  
  void me( void functResponse(FacebookMe response) , [ bool reuseCached ] ) {
    
    if (reuseCached == true && _lastMe != null) {
      functResponse(_lastMe) ;
      return ;
    }
    
    Function functWrapper = (JsObject response) {
      FacebookMe me = _catch_Me(response) ;
      if (functResponse != null) functResponse(me) ;
    } ;
    
    api('/me', functWrapper) ;
    
  }
  
  void fqlQuery(String fqlQuery, void functResponse(JsObject response)  ) {
    
    Map params = { 'q': fqlQuery } ;
    
    api('/fql', functResponse, params ) ;
    
  }

  //////////////////////////////////////////////////////////////
  
  StreamController<FacebookLoginStatus> _controller_onLogin = new StreamController<FacebookLoginStatus>() ;
  Stream<FacebookLoginStatus> get onLogin => _controller_onLogin.stream ;
  
  StreamController<FacebookLoginStatus> _controller_onAlreadyLogged = new StreamController<FacebookLoginStatus>() ;
  Stream<FacebookLoginStatus> get onAlreadyLogged => _controller_onAlreadyLogged.stream ;
  
  StreamController<FacebookLoginStatus> _controller_onLogout = new StreamController<FacebookLoginStatus>() ;
  Stream<FacebookLoginStatus> get onLogout => _controller_onLogout.stream ;
  
  ///////////////////////////////////////////////////////////////
  
  FacebookLoginStatus _lastLoginStatus ;
  
  FacebookLoginStatus get lastLoginStatus => _lastLoginStatus ;
  
  bool get isConnected => _lastLoginStatus != null && _lastLoginStatus.isConnected ;
  
  String get currentUserID => _lastLoginStatus != null ? _lastLoginStatus.userID : null ;
  
  bool _notifiedLogin = false ;
  
  FacebookLoginStatus _catch_LoginStatus(JsObject loginStatus, bool fromLoginCall) {
   
    _lastLoginStatus = new FacebookLoginStatus(loginStatus) ;
    
    if ( _lastLoginStatus.isConnected ) {
      me(null) ;
    }
    
    if (fromLoginCall) {
    
      _notifiedLogin = true ;
      _controller_onLogin.add(_lastLoginStatus) ;
    
    }
    else {
    
      if ( !_notifiedLogin && _lastLoginStatus.isConnected ) {
        _controller_onAlreadyLogged.add(_lastLoginStatus) ;
      }
      
    }
    
    return _lastLoginStatus ;
  }
  
  FacebookLoginStatus _catch_Logout(JsObject loginStatus) {
    
    _lastLoginStatus = new FacebookLoginStatus(loginStatus) ;
    
    _controller_onLogout.add(_lastLoginStatus) ;
    
    return _lastLoginStatus ;
  }
  
  ///////////////////////////////////////////////////////////////
  
  FacebookMe _lastMe ;
  
  FacebookMe get lastMe => _lastMe ;
  
  FacebookMe _catch_Me(JsObject meResponse) {
    
    _lastMe = new FacebookMe(meResponse) ;
    
    return _lastMe ;
    
  }
  
  ///////////////////////////////////////////////////////////////
  
  void queryFriends( void functResponse( List<FacebookFriend> friends ) ) {
  
    /*
    api('/me/friends', (JsObject resp) {
      _processQueryFriends(resp, functResponse) ;
    }) ;
    */
    
    List<FacebookFriend> friendsList = [] ;
    
    api('/me/friends', (JsObject resp) {
      _processQueryFriends(resp, friendsList, (l) {
        
        api('/me/invitable_friends', (JsObject resp) {
          _processQueryFriends(resp, friendsList, functResponse) ;          
        });
        
      }) ;
    }) ;
    
  }
  
  void queryOnlineFriends( void functResponse( List<FacebookFriend> friends ) ) {
    
    String fql = "SELECT uid, name FROM user WHERE " +
        "online_presence IN ('active', 'idle') AND " +
        "uid IN (" +
        "SELECT uid2 FROM friend WHERE uid1 = me()" +
        ")" ;

    
    fqlQuery(fql, (JsObject resp) {
      _processQueryFriends(resp, [],functResponse) ;
    });
    
  }
  
  void _processQueryFriends( JsObject resp , List<FacebookFriend> friendsList, void functResponse( List<FacebookFriend> friends )  ) {
    if (friendsList == null) friendsList = [] ;
    
    var data = resp['data'] ;
    
    num sz = 0 ;
    
    if ( data is JsArray ) {
      JsArray dataJsArray = data ;
      sz = dataJsArray != null ? dataJsArray.length : 0 ;
    }
    else {
      sz = data != null ? data.length : 0 ;  
    }
    
    
    
    for (int i = 0 ; i < sz ; i++) {
      var user = data[i] ;
      
      var id = user['id'] ;
      if (id == null) id = user['uid'] ;
      
      String uid = null ;
      String idCode = null ;
      
      if (id != null) {
        String idStr = id.toString() ;
        if (idStr.length < 50) {
          uid = idStr ;
        }
        else {
          idCode = idStr ;
        }
      }
      
      String name = user['name'] ;
      
      var picture = user['picture'] ;
      
      String pictureURL = null ;
      if (picture != null) {
        JsObject picData = picture['data'] ;
        pictureURL = picData['url'] ; 
      }
      
      FacebookFriend fbFriend = new FacebookFriend(uid, name, pictureURL, idCode) ;
      
      if ( !FacebookFriend.containsSameFriend(friendsList, fbFriend) ) {
        friendsList.add(fbFriend) ;  
      }
      
    }
    
    functResponse(friendsList) ;
  }
  
}

//////////////////////////////////////////////////////////

class FacebookFriend {
  
  static bool containsSameFriend(List<FacebookFriend> list, FacebookFriend friend) {
    
    for (var f in list) {
      if ( f != null && friend.isSame(f) ) return true ;
    }
    
    return false ;
  }
  
  String _uid ;
  String _name ;
  String _pictureURL ;
  String _invitationCode ;
  
  FacebookFriend(this._uid , this._name , this._pictureURL, this._invitationCode) {
    
    if (this._pictureURL == null && this._uid != null) {
      this._pictureURL = FacebookAPI.getPictureURL_fromUserID(uid) ;
    }
    
  }
  
  String get uid => _uid ;
  String get name => _name ;
  String get pictureURL => _pictureURL ;
  String get invitationCode => _invitationCode ;
  
  bool isSame(FacebookFriend other) {
    if ( this._uid != null && this._uid == other._uid ) return true ;
    if ( this._pictureURL != null && this._pictureURL == other._pictureURL ) return true ;
    if ( this._invitationCode != null && this._invitationCode == other._invitationCode ) return true ;
    return false ;
  }
  
}

class FacebookLoginStatus {
  JsObject _obj ;
  
  FacebookLoginStatus(JsObject obj) {
    this._obj = obj ;
  }
  
  bool get isConnected => _obj['status'] == 'connected' ;
  
  get authResponse => _obj['authResponse'] ;
  
  String get accessToken => _obj['authResponse'] != null ? _obj['authResponse']['accessToken'] : null ;
  
  String get userID => _obj['authResponse'] != null ? _obj['authResponse']['userID'] : null ;
  
  num get expiresIn => _obj['authResponse'] != null ? _obj['authResponse']['expiresIn'] : null ;
  
  String get signedRequest => _obj['authResponse'] != null ? _obj['authResponse']['signedRequest'] : null ;
  
  String toString() {
    return FacebookAPI.toJSON_String(_obj) ;
  }
}

class FacebookMe {
  JsObject _obj ;
  
  FacebookMe(JsObject obj) {
    this._obj = obj ;
  }
  
  String get id => _obj['id'] ;
  
  String get name => _obj['name'] ;
  
  String get first_name => _obj['first_name'] ;
  
  String get middle_name => _obj['middle_name'] ;
  
  String get last_name => _obj['last_name'] ;
  
  String get link => _obj['link'] ;
  
  get education => _obj['education'] ;
  
  String get gender => _obj['gender'] ;
  
  String get email => _obj['email'] ;
  
  String get timezone => _obj['timezone'] ;
  
  String get locale => _obj['locale'] ;
  
  bool get verified => _obj['verified'] == 'true' ;
  
  String get updated_time => _obj['updated_time'] ;
  
  String get username => _obj['username'] ;
  
  String toString() {
    return FacebookAPI.toJSON_String(_obj) ;
  }
}



