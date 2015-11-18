// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/stub_code.h"

#include "platform/assert.h"
#include "platform/globals.h"
#include "vm/assembler.h"
#include "vm/disassembler.h"
#include "vm/flags.h"
#include "vm/object_store.h"
#include "vm/snapshot.h"
#include "vm/virtual_memory.h"
#include "vm/visitor.h"

namespace dart {

DEFINE_FLAG(bool, disassemble_stubs, false, "Disassemble generated stubs.");

#define STUB_CODE_DECLARE(name)                                                \
  StubEntry* StubCode::name##_entry_ = NULL;
VM_STUB_CODE_LIST(STUB_CODE_DECLARE);
#undef STUB_CODE_DECLARE


StubEntry::StubEntry(const Code& code)
    : code_(code.raw()),
      entry_point_(code.EntryPoint()),
      size_(code.Size()),
      label_(code.EntryPoint()) {
}


// Visit all object pointers.
void StubEntry::VisitObjectPointers(ObjectPointerVisitor* visitor) {
  ASSERT(visitor != NULL);
  visitor->VisitPointer(reinterpret_cast<RawObject**>(&code_));
}


#define STUB_CODE_GENERATE(name)                                               \
  code ^= Generate("_stub_"#name, StubCode::Generate##name##Stub);             \
  name##_entry_ = new StubEntry(code);


void StubCode::InitOnce() {
  // Generate all the stubs.
  Code& code = Code::Handle();
  VM_STUB_CODE_LIST(STUB_CODE_GENERATE);
}


#undef STUB_CODE_GENERATE


void StubCode::ReadFrom(SnapshotReader* reader) {
#define READ_STUB(name)                                                        \
  *(reader->CodeHandle()) ^= reader->ReadObject();                             \
  name##_entry_ = new StubEntry(*(reader->CodeHandle()));
  VM_STUB_CODE_LIST(READ_STUB);
#undef READ_STUB
}

void StubCode::WriteTo(SnapshotWriter* writer) {
  // TODO(rmacnak): Consider writing only the instructions to avoid
  // vm_isolate_is_symbolic.
#define WRITE_STUB(name)                                                       \
  writer->WriteObject(StubCode::name##_entry()->code());
  VM_STUB_CODE_LIST(WRITE_STUB);
#undef WRITE_STUB
}


void StubCode::Init(Isolate* isolate) { }


void StubCode::VisitObjectPointers(ObjectPointerVisitor* visitor) {
}


bool StubCode::InInvocationStub(uword pc) {
  uword entry = StubCode::InvokeDartCode_entry()->EntryPoint();
  uword size = StubCode::InvokeDartCodeSize();
  return (pc >= entry) && (pc < (entry + size));
}


bool StubCode::InJumpToExceptionHandlerStub(uword pc) {
  uword entry = StubCode::JumpToExceptionHandler_entry()->EntryPoint();
  uword size = StubCode::JumpToExceptionHandlerSize();
  return (pc >= entry) && (pc < (entry + size));
}


RawCode* StubCode::GetAllocationStubForClass(const Class& cls) {
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  const Error& error = Error::Handle(zone, cls.EnsureIsFinalized(thread));
  ASSERT(error.IsNull());
  if (cls.id() == kArrayCid) {
    return AllocateArray_entry()->code();
  }
  Code& stub = Code::Handle(zone, cls.allocation_stub());
  if (stub.IsNull()) {
    Assembler assembler;
    const char* name = cls.ToCString();
    StubCode::GenerateAllocationStubForClass(&assembler, cls);
    stub ^= Code::FinalizeCode(name, &assembler);
    stub.set_owner(cls);
    cls.set_allocation_stub(stub);
    if (FLAG_disassemble_stubs) {
      LogBlock lb;
      THR_Print("Code for allocation stub '%s': {\n", name);
      DisassembleToStdout formatter;
      stub.Disassemble(&formatter);
      THR_Print("}\n");
      const ObjectPool& object_pool = ObjectPool::Handle(stub.object_pool());
      object_pool.DebugPrint();
    }
  }
  return stub.raw();
}


const StubEntry* StubCode::UnoptimizedStaticCallEntry(
    intptr_t num_args_tested) {
  switch (num_args_tested) {
    case 0:
      return ZeroArgsUnoptimizedStaticCall_entry();
    case 1:
      return OneArgUnoptimizedStaticCall_entry();
    case 2:
      return TwoArgsUnoptimizedStaticCall_entry();
    default:
      UNIMPLEMENTED();
      return NULL;
  }
}


RawCode* StubCode::Generate(const char* name,
                            void (*GenerateStub)(Assembler* assembler)) {
  Assembler assembler;
  GenerateStub(&assembler);
  const Code& code = Code::Handle(Code::FinalizeCode(name, &assembler));
  if (FLAG_disassemble_stubs) {
    LogBlock lb;
    THR_Print("Code for stub '%s': {\n", name);
    DisassembleToStdout formatter;
    code.Disassemble(&formatter);
    THR_Print("}\n");
    const ObjectPool& object_pool = ObjectPool::Handle(code.object_pool());
    object_pool.DebugPrint();
  }
  return code.raw();
}


const char* StubCode::NameOfStub(uword entry_point) {
#define VM_STUB_CODE_TESTER(name)                                              \
  if ((name##_entry() != NULL) &&                                              \
      (entry_point == name##_entry()->EntryPoint())) {                         \
    return ""#name;                                                            \
  }
  VM_STUB_CODE_LIST(VM_STUB_CODE_TESTER);
#undef VM_STUB_CODE_TESTER
  return NULL;
}

}  // namespace dart
