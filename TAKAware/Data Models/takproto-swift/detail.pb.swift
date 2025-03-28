// DO NOT EDIT.
// swift-format-ignore-file
// swiftlint:disable all
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: detail.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Atakmap_Commoncommo_Protobuf_V1_Detail: Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var xmlDetail: String = String()

  /// <contact>
  var contact: Atakmap_Commoncommo_Protobuf_V1_Contact {
    get {return _contact ?? Atakmap_Commoncommo_Protobuf_V1_Contact()}
    set {_contact = newValue}
  }
  /// Returns true if `contact` has been explicitly set.
  var hasContact: Bool {return self._contact != nil}
  /// Clears the value of `contact`. Subsequent reads from it will return its default value.
  mutating func clearContact() {self._contact = nil}

  /// <__group>
  var group: Atakmap_Commoncommo_Protobuf_V1_Group {
    get {return _group ?? Atakmap_Commoncommo_Protobuf_V1_Group()}
    set {_group = newValue}
  }
  /// Returns true if `group` has been explicitly set.
  var hasGroup: Bool {return self._group != nil}
  /// Clears the value of `group`. Subsequent reads from it will return its default value.
  mutating func clearGroup() {self._group = nil}

  /// <precisionlocation>
  var precisionLocation: Atakmap_Commoncommo_Protobuf_V1_PrecisionLocation {
    get {return _precisionLocation ?? Atakmap_Commoncommo_Protobuf_V1_PrecisionLocation()}
    set {_precisionLocation = newValue}
  }
  /// Returns true if `precisionLocation` has been explicitly set.
  var hasPrecisionLocation: Bool {return self._precisionLocation != nil}
  /// Clears the value of `precisionLocation`. Subsequent reads from it will return its default value.
  mutating func clearPrecisionLocation() {self._precisionLocation = nil}

  /// <status>
  var status: Atakmap_Commoncommo_Protobuf_V1_Status {
    get {return _status ?? Atakmap_Commoncommo_Protobuf_V1_Status()}
    set {_status = newValue}
  }
  /// Returns true if `status` has been explicitly set.
  var hasStatus: Bool {return self._status != nil}
  /// Clears the value of `status`. Subsequent reads from it will return its default value.
  mutating func clearStatus() {self._status = nil}

  /// <takv>
  var takv: Atakmap_Commoncommo_Protobuf_V1_Takv {
    get {return _takv ?? Atakmap_Commoncommo_Protobuf_V1_Takv()}
    set {_takv = newValue}
  }
  /// Returns true if `takv` has been explicitly set.
  var hasTakv: Bool {return self._takv != nil}
  /// Clears the value of `takv`. Subsequent reads from it will return its default value.
  mutating func clearTakv() {self._takv = nil}

  /// <track>
  var track: Atakmap_Commoncommo_Protobuf_V1_Track {
    get {return _track ?? Atakmap_Commoncommo_Protobuf_V1_Track()}
    set {_track = newValue}
  }
  /// Returns true if `track` has been explicitly set.
  var hasTrack: Bool {return self._track != nil}
  /// Clears the value of `track`. Subsequent reads from it will return its default value.
  mutating func clearTrack() {self._track = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _contact: Atakmap_Commoncommo_Protobuf_V1_Contact? = nil
  fileprivate var _group: Atakmap_Commoncommo_Protobuf_V1_Group? = nil
  fileprivate var _precisionLocation: Atakmap_Commoncommo_Protobuf_V1_PrecisionLocation? = nil
  fileprivate var _status: Atakmap_Commoncommo_Protobuf_V1_Status? = nil
  fileprivate var _takv: Atakmap_Commoncommo_Protobuf_V1_Takv? = nil
  fileprivate var _track: Atakmap_Commoncommo_Protobuf_V1_Track? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "atakmap.commoncommo.protobuf.v1"

extension Atakmap_Commoncommo_Protobuf_V1_Detail: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Detail"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "xmlDetail"),
    2: .same(proto: "contact"),
    3: .same(proto: "group"),
    4: .same(proto: "precisionLocation"),
    5: .same(proto: "status"),
    6: .same(proto: "takv"),
    7: .same(proto: "track"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.xmlDetail) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._contact) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._group) }()
      case 4: try { try decoder.decodeSingularMessageField(value: &self._precisionLocation) }()
      case 5: try { try decoder.decodeSingularMessageField(value: &self._status) }()
      case 6: try { try decoder.decodeSingularMessageField(value: &self._takv) }()
      case 7: try { try decoder.decodeSingularMessageField(value: &self._track) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    if !self.xmlDetail.isEmpty {
      try visitor.visitSingularStringField(value: self.xmlDetail, fieldNumber: 1)
    }
    try { if let v = self._contact {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    } }()
    try { if let v = self._group {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    try { if let v = self._precisionLocation {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    } }()
    try { if let v = self._status {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    } }()
    try { if let v = self._takv {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 6)
    } }()
    try { if let v = self._track {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 7)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Atakmap_Commoncommo_Protobuf_V1_Detail, rhs: Atakmap_Commoncommo_Protobuf_V1_Detail) -> Bool {
    if lhs.xmlDetail != rhs.xmlDetail {return false}
    if lhs._contact != rhs._contact {return false}
    if lhs._group != rhs._group {return false}
    if lhs._precisionLocation != rhs._precisionLocation {return false}
    if lhs._status != rhs._status {return false}
    if lhs._takv != rhs._takv {return false}
    if lhs._track != rhs._track {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
