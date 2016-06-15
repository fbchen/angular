library angular2.test.compiler.output.output_emitter_spec;

import "package:angular2/testing_internal.dart"
    show
        AsyncTestCompleter,
        beforeEach,
        ddescribe,
        describe,
        el,
        expect,
        iit,
        inject,
        it,
        xit,
        TestComponentBuilder,
        browserDetection;
import "package:angular2/src/facade/lang.dart" show IS_DART;
import "output_emitter_codegen_typed.dart" as typed;
import "output_emitter_codegen_untyped.dart" as untyped;
import "package:angular2/src/compiler/output/output_jit.dart"
    show jitStatements;
import "package:angular2/src/compiler/output/output_interpreter.dart"
    show interpretStatements;
import "output_emitter_util.dart"
    show codegenStmts, ExternalClass, DynamicClassInstanceFactory;
import "package:angular2/src/facade/async.dart" show EventEmitter;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;

main() {
  var outputDefs = [];
  outputDefs.add({
    "getExpressions": () => interpretStatements(
        codegenStmts, "getExpressions", new DynamicClassInstanceFactory()),
    "name": "interpreted"
  });
  if (IS_DART || !DOM.supportsDOMEvents()) {
    // Our generator only works on node.js and Dart...
    outputDefs
        .add({"getExpressions": () => typed.getExpressions, "name": "typed"});
  }
  if (!IS_DART) {
    // Our generator only works on node.js and Dart...
    if (!DOM.supportsDOMEvents()) {
      outputDefs.add(
          {"getExpressions": () => untyped.getExpressions, "name": "untyped"});
    }
    outputDefs.add({
      "getExpressions": () =>
          jitStatements("output_emitter_spec", codegenStmts, "getExpressions"),
      "name": "jit"
    });
  }
  describe("output emitter", () {
    outputDefs.forEach((outputDef) {
      describe('''${ outputDef [ "name" ]}''', () {
        var expressions;
        beforeEach(() {
          expressions = outputDef["getExpressions"]()();
        });
        it("should support literals", () {
          expect(expressions["stringLiteral"]).toEqual("Hello World!");
          expect(expressions["intLiteral"]).toEqual(42);
          expect(expressions["boolLiteral"]).toEqual(true);
          expect(expressions["arrayLiteral"]).toEqual([0]);
          expect(expressions["mapLiteral"]).toEqual({"key0": 0});
        });
        it("should support reading vars/keys/props", () {
          expect(expressions["readVar"]).toEqual("someValue");
          expect(expressions["readKey"]).toEqual("someValue");
          expect(expressions["readPropExternalInstance"]).toEqual("someValue");
          expect(expressions["readPropDynamicInstance"])
              .toEqual("dynamicValue");
          expect(expressions["readGetterDynamicInstance"])
              .toEqual({"data": "someValue", "dynamicProp": "dynamicValue"});
        });
        it("should support writing to vars / keys / props", () {
          expect(expressions["changedVar"]).toEqual("changedValue");
          expect(expressions["changedKey"]).toEqual("changedValue");
          expect(expressions["changedPropExternalInstance"])
              .toEqual("changedValue");
          expect(expressions["changedPropDynamicInstance"])
              .toEqual("changedValue");
        });
        it("should support declaring functions with parameters and return", () {
          expect(expressions["fn"]("someParam"))
              .toEqual({"param": "someParam"});
          expect(expressions["closureInDynamicInstance"]("someParam")).toEqual({
            "param": "someParam",
            "data": "someValue",
            "dynamicProp": "dynamicValue"
          });
        });
        it("should support invoking functions and methods", () {
          expect(expressions["invokeFn"]).toEqual({"param": "someParam"});
          expect(expressions["concatedArray"]).toEqual([0, 1]);
          expect(expressions["invokeMethodExternalInstance"])
              .toEqual({"data": "someValue", "param": "someParam"});
          expect(expressions["invokeMethodDynamicInstance"]).toEqual({
            "data": "someValue",
            "dynamicProp": "dynamicValue",
            "param": "someParam"
          });
        });
        it("should support conditionals", () {
          expect(expressions["conditionalTrue"]).toEqual("true");
          expect(expressions["conditionalFalse"]).toEqual("false");
        });
        it("should support not", () {
          expect(expressions["not"]).toEqual(true);
        });
        it("should support reading external identifiers", () {
          expect(expressions["externalTestIdentifier"]).toBe(ExternalClass);
          expect(expressions["externalSrcIdentifier"]).toBe(EventEmitter);
          expect(expressions["externalEnumIdentifier"]).toBe(ViewType.HOST);
        });
        it("should support instantiating classes", () {
          expect(expressions["externalInstance"])
              .toBeAnInstanceOf(ExternalClass);
          // Note: toBeAnInstanceOf does not check super classes in Dart...
          expect(expressions["dynamicInstance"] is ExternalClass).toBe(true);
        });
        it("should support reading metadataMap", () {
          if (IS_DART && outputDef["name"] == "typed") {
            expect(expressions["metadataMap"])
                .toEqual(["someKey", "someValue"]);
          } else {
            expect(expressions["metadataMap"]).toBe(null);
          }
        });
        describe("operators", () {
          var ops;
          var aObj, bObj;
          beforeEach(() {
            ops = expressions["operators"];
            aObj = new Object();
            bObj = new Object();
          });
          it("should support ==", () {
            expect(ops["=="](aObj, aObj)).toBe(true);
            expect(ops["=="](aObj, bObj)).toBe(false);
            expect(ops["=="](1, 1)).toBe(true);
            expect(ops["=="](0, 1)).toBe(false);
            expect(ops["=="]("a", "a")).toBe(true);
            expect(ops["=="]("a", "b")).toBe(false);
          });
          it("should support !=", () {
            expect(ops["!="](aObj, aObj)).toBe(false);
            expect(ops["!="](aObj, bObj)).toBe(true);
            expect(ops["!="](1, 1)).toBe(false);
            expect(ops["!="](0, 1)).toBe(true);
            expect(ops["!="]("a", "a")).toBe(false);
            expect(ops["!="]("a", "b")).toBe(true);
          });
          it("should support ===", () {
            expect(ops["==="](aObj, aObj)).toBe(true);
            expect(ops["==="](aObj, bObj)).toBe(false);
            expect(ops["==="](1, 1)).toBe(true);
            expect(ops["==="](0, 1)).toBe(false);
          });
          it("should support !==", () {
            expect(ops["!=="](aObj, aObj)).toBe(false);
            expect(ops["!=="](aObj, bObj)).toBe(true);
            expect(ops["!=="](1, 1)).toBe(false);
            expect(ops["!=="](0, 1)).toBe(true);
          });
          it("should support -", () {
            expect(ops["-"](3, 2)).toEqual(1);
          });
          it("should support +", () {
            expect(ops["+"](1, 2)).toEqual(3);
          });
          it("should support /", () {
            expect(ops["/"](6, 2)).toEqual(3);
          });
          it("should support *", () {
            expect(ops["*"](2, 3)).toEqual(6);
          });
          it("should support %", () {
            expect(ops["%"](3, 2)).toEqual(1);
          });
          it("should support &&", () {
            expect(ops["&&"](true, true)).toBe(true);
            expect(ops["&&"](true, false)).toBe(false);
          });
          it("should support ||", () {
            expect(ops["||"](true, false)).toBe(true);
            expect(ops["||"](false, false)).toBe(false);
          });
          it("should support <", () {
            expect(ops["<"](1, 2)).toBe(true);
            expect(ops["<"](1, 1)).toBe(false);
          });
          it("should support <=", () {
            expect(ops["<="](1, 2)).toBe(true);
            expect(ops["<="](1, 1)).toBe(true);
          });
          it("should support >", () {
            expect(ops[">"](2, 1)).toBe(true);
            expect(ops[">"](1, 1)).toBe(false);
          });
          it("should support >=", () {
            expect(ops[">="](2, 1)).toBe(true);
            expect(ops[">="](1, 1)).toBe(true);
          });
        });
        it("should support throwing errors", () {
          expect(expressions["throwError"]).toThrowError("someError");
        });
        it("should support catching errors", () {
          someOperation() {
            throw new BaseException("Boom!");
          }
          var errorAndStack = expressions["catchError"](someOperation);
          expect(errorAndStack[0].message).toEqual("Boom!");
          // Somehow we don't get stacktraces on ios7...
          if (!browserDetection.isIOS7 && !browserDetection.isIE) {
            expect(errorAndStack[1].toString()).toContain("someOperation");
          }
        });
      });
    });
  });
}
