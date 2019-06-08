var exec = require('cordova/exec');

var cameraRoll = {};

cameraRoll.getPhotos = function(successCallback, errorCallback, options) {
  const count = options ? options.count : 0;
  exec(successCallback, errorCallback, "CameraRoll", "getPhotos", [count || 0]);
};

cameraRoll.getVideoThumbnail = function(successCallback, errorCallback, options) {
  const count = options ? options.ruta : 0;
  exec(successCallback, errorCallback, "CameraRoll", "getVideoThumbnail", [count || 0]);
};

cameraRoll.obtenerLivePhotos = function(successCallback, errorCallback, options) {
  const count = options ? options.count : 0;
  exec(successCallback, errorCallback, "CameraRoll", "obtenerLivePhotos", [count || 0]);
};

cameraRoll.getVideos = function(successCallback, errorCallback, options) {
  const count = options ? options.count : 0;
  exec(successCallback, errorCallback, "CameraRoll", "getVideos", [count || 0]);
};

cameraRoll.saveToCameraRoll = function(imageBase64, successCallback, errorCallback, options) {
  exec(successCallback, errorCallback, "CameraRoll", "saveToCameraRoll", [imageBase64]);
};

module.exports = cameraRoll;
