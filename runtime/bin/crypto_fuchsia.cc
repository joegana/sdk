// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/crypto.h"

#include <zircon/syscalls.h>

namespace dart {
namespace bin {

bool Crypto::GetRandomBytes(intptr_t count, uint8_t* buffer) {
  intptr_t read = 0;
  while (read < count) {
    const intptr_t remaining = count - read;
    const intptr_t len =
        (ZX_CPRNG_DRAW_MAX_LEN < remaining) ? ZX_CPRNG_DRAW_MAX_LEN : remaining;
    const zx_status_t status = zx_cprng_draw_new(buffer + read, len);
    if (status != ZX_OK) {
      return false;
    }
    read += len;
  }
  return true;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
