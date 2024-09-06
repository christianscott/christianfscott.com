---
title: "Bazel remote caching: Action caches are more secure when they're readonly"
date: "2024-09-05T23:13:13.625Z"
---

Bazel remote caches are made up of two parts: the Action Cache _(AC)_ and the Content Addressable Store _(CAS)_. The AC stores the results of previous builds and tests, and the CAS is basically a file store. To prevent certain types of attacks, it’s important for the AC to be readonly. It’s not necessary for the CAS to be readonly, however, assuming certain checks are in place. Making the AC readonly forces you to change the way you run your builds, so you’ll need to decide if the tradeoff is worth it.

Bazel performs work using a concept called an Action. An action is a data structure that represents a command that needs to be run, plus the inputs. For example, an action that makes a copy of `hello.txt` might look like this [^1]:

```javascript
// heavily simplified json for an `Action`
{
  "command": {
    "arguments": ["bash", "-c", "cp hello.txt hello_copy.txt"]
  },
  "inputs": {
    "hello.txt": "5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03/12"
  }
}
```

These actions can be run locally by Bazel, or they can run remotely by sending a request containing the action to a remote execution cluster. Notice any input files are referred to by a digest (`5891b[..]/12`), which is made up of the checksum of the file plus its size in bytes. This is essentially a “pointer” into the CAS. The CAS is a key-value store of files, where the key is the digest of the file. Before an action can be run remotely, Bazel has to upload all the input files it references to the CAS:

```python
action = self.make_action()
for f in action.input_files:
    digest = f"{shasum(f)}/{len(f)}"
    self.upload_to_cas(key=digest, contents=f)
action_result = self.execute_action(action)
```

The result of an action execution is a data structure called an Action Result. The most important field in the action result is the “outputs”, which is a key-value map of output filename to digest:

```javascript
// heavily simplified json for an `ActionResult`
{
  "outputs": {
    "hello_copy.txt": "5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03/12"
  }
}
```

When the action has finished executing the action result will be written to the AC. The AC is a key-value store of action results, keyed by the action. The AC is what allows Bazel to re-use the result of builds run on other machines. To check if an action has been run before, Bazel will compute the digest of an action and perform a lookup in the AC. If there is a cache hit, Bazel will simply download the previously computed result rather than executing the action again. This means that an identical action will only be run once across many machines running Bazel.

```python
action = self.make_action()
if (action_result := self.get_action_result(key=digest(action))) is not None:
    return action_result # cache hit
for f in action.input_files:
    self.upload_to_cas(key=digest(f), contents=f)
action_result = self.execute_action(action)
self.put_action_result(key=digest(action), value=action_result)
```

Notice that the CAS entries are content addressed (`key=digest(file)`), whereas the AC is input addressed (`key=digest(action)`, rather than `key=digest(action_result)`). This means that it’s possible to verify the validity of a CAS entry by recomputing the digest. If an attacker tries to upload a malicious file to the CAS, they cannot overwrite benign data with malicious data. Server-side checks will reject any uploads where the key doesn’t match the actual digest. Even if these server-side checks weren’t in place, Bazel itself verifies that the digest is correct for any file it downloads from the CAS.

In contrast to the CAS, the fact that the AC is input addressed means there is no way to verify the validity of an AC entry based on its key. You have to trust that any data you get from the AC is correct and hasn’t been placed there by an attacker. This means that while an attacker cannot exploit write access to the CAS, they can exploit write access to the AC:

```python
# Step 1: upload malicious .jar to the CAS
malicious_jar = open("./MaliciousService.jar", "r")
self.upload_to_cas(key=digest(malicious_jar), value=malicious_jar)
# Step 2: grab the original action result and modify it
action_result = self.get_action_result(action)
action_result.outputs["Service.jar"] = digest(malicious_jar)
# Step 3: upload the poisoned action result
self.put_action_result(key=digest(action), value=action_result)
```

Unfortunately, any remote cache that supports local (i.e. non-RBE) execution must support writes to the AC. Otherwise it’s impossible for Bazel to share cache hits across many machines.

The only way you can turn off write access to the AC is by running actions remotely. In this setup, the remote execution service itself will write action results to the AC. In theory[^2] the only way to poison the cache in this scenario is to find a hash collision between a benign action and a malicious one, which is extraordinarily unlikely considering Bazel uses SHA-256.

[^1]: I have taken some creative liberties to make this easier to understand for someone who isn't familiar with Bazel's remote APIs. `Action`s and `ActionResult`s don't actually have this shape, nor are they encoded using JSON. You can see the real data structures in the [bazelbuild/remote-apis](https://github.com/bazelbuild/remote-apis/blob/0d21f29acdb90e1b67db5873e227051af0c80cdd/build/bazel/remote/execution/v2/remote_execution.proto) repo.

[^2]: In practice there are other ways that an attacker can exploit RBE to poison the cache, like writing to the AC directly from inside an action if access controls have not been configured properly.
