# PHP Version Compatibility Guide

## PHP 8.1 Code with PHP 8.4

When using Laravel code written for PHP 8.1 with PHP 8.4, you may encounter:

### 1. **Deprecation Warnings** ✅ (Already Suppressed)
- **Issue**: Implicit nullable parameters, deprecated functions
- **Example**: `Deprecated: optional(): Implicitly marking parameter $callback as nullable is deprecated`
- **Solution**: Already configured in `docker/php/local.ini` to suppress these warnings

### 2. **Type System Changes**
- **Issue**: PHP 8.4 has stricter type checking
- **Impact**: Some code that worked in 8.1 might need explicit type declarations
- **Solution**: Suppress deprecation warnings (already done) or update code gradually

#### **Practical Examples:**

**Example 1: Implicit Nullable Parameters (Most Common Issue)**

**PHP 8.1 Code (Works but deprecated in 8.4):**
```php
function processUser($callback = null) {
    if ($callback !== null) {
        return $callback();
    }
    return 'default';
}
```

**PHP 8.4 Compatible Code:**
```php
function processUser(?callable $callback = null) {
    if ($callback !== null) {
        return $callback();
    }
    return 'default';
}
```

**Migration Strategy:**
1. **Start with deprecation warnings suppressed** (already configured)
2. **Gradually add type hints** to new code
3. **Update existing code** when you touch it during normal development
4. **Use static analysis tools** like PHPStan or Psalm to find issues
5. **Test thoroughly** after making changes

## Writing Forward-Compatible Code (PHP 8.1 → 8.4)

If you need to write code that works in both PHP 8.1 and 8.4, follow these best practices:

### **Best Practices for Forward Compatibility:**

#### **1. Always Use Explicit Nullable Types**

**✅ Good (Works in both 8.1 and 8.4):**
```php
function processUser(?callable $callback = null): string {
    if ($callback !== null) {
        return $callback();
    }
    return 'default';
}
```

**❌ Avoid (Deprecated in 8.4):**
```php
function processUser($callback = null) {
    // This will show deprecation warnings in 8.4
}
```

#### **2. Add Return Type Declarations**

**✅ Good (Works in both 8.1 and 8.4):**
```php
function getUserData(int $id): ?User {
    return User::find($id);
}
```

**❌ Avoid:**
```php
function getUserData($id) {
    return User::find($id);
}
```

#### **3. Use Type Hints for Parameters**

**✅ Good:**
```php
function processItems(array $items): void {
    foreach ($items as $item) {
        // process item
    }
}
```

**❌ Avoid:**
```php
function processItems($items) {
    // Missing type hints
}
```

#### **4. Use Modern String Functions**

**✅ Good (Works in both 8.1 and 8.4):**
```php
// For non-ASCII characters, use mb_* functions
$lower = mb_strtolower($text, 'UTF-8');
$upper = mb_strtoupper($text, 'UTF-8');
$first = mb_ucfirst($text, 'UTF-8');
```

**❌ Avoid (Deprecated in 8.4 for non-ASCII):**
```php
$lower = strtolower($text); // Deprecated for non-ASCII in 8.4
$upper = strtoupper($text); // Deprecated for non-ASCII in 8.4
```

#### **5. Always Provide Encoding Parameters**

**✅ Good:**
```php
$encoded = htmlspecialchars($text, ENT_QUOTES, 'UTF-8');
$converted = mb_convert_encoding($text, 'UTF-8', 'ISO-8859-1');
$iconv = iconv('ISO-8859-1', 'UTF-8', $text);
```

**❌ Avoid (Deprecated in 8.4):**
```php
$encoded = htmlspecialchars($text); // Missing encoding
$converted = mb_convert_encoding($text, 'UTF-8'); // Missing from_encoding
```

#### **6. Avoid Removed Functions**

**✅ Good:**
```php
// Use mysqli_get_client_info() with connection parameter
$info = mysqli_get_client_info($connection);

// Use ReflectionClass methods properly
$reflection = new ReflectionClass($class);
$properties = $reflection->getProperties(ReflectionProperty::IS_STATIC);
```

**❌ Avoid (Removed in 8.4):**
```php
$info = mysqli_get_client_info(); // Missing parameter - removed in 8.4
$properties = $reflection->getStaticProperties(); // Removed in 8.4
```

#### **7. Use Union Types (PHP 8.0+)**

**✅ Good (Works in both 8.1 and 8.4):**
```php
function formatValue(string|int|float $value): string {
    return (string) $value;
}
```

#### **8. Laravel-Specific Recommendations**

**✅ Good:**
```php
// Use Laravel's built-in helpers (already compatible)
$value = optional($user)->name;
$value = value(function() { return 'computed'; });

// Use type hints in controllers
public function show(int $id): JsonResponse {
    return response()->json(User::findOrFail($id));
}
```

**✅ Good for Custom Helpers:**
```php
// Always use explicit nullable types
function customHelper($value, ?callable $callback = null) {
    // implementation
}
```

### **Quick Reference Checklist:**

When writing new code in PHP 8.1 that should work in 8.4:

- ✅ Always use explicit nullable types (`?type`)
- ✅ Add return type declarations (`: returnType`)
- ✅ Use parameter type hints (`type $param`)
- ✅ Use `mb_*` functions for non-ASCII strings
- ✅ Always provide encoding parameters
- ✅ Avoid deprecated/removed functions
- ✅ Use union types when appropriate
- ✅ Test with both PHP 8.1 and 8.4 if possible

### **Composer Configuration:**

In your `composer.json`, you can specify PHP version requirements:

```json
{
    "require": {
        "php": "^8.1|^8.2|^8.3|^8.4"
    }
}
```

This ensures your code works across all these versions.

### 3. **Removed/Deprecated Functions**

#### **Functions Removed in PHP 8.4:**
- **`mb_ereg_replace_callback()`** - Removed (deprecated in PHP 8.1)
- **`ldap_connect()` with 2 parameters** - Removed (deprecated in PHP 8.1)
- **`ldap_control_paged_result()`** - Removed (deprecated in PHP 8.0)
- **`ldap_control_paged_result_response()`** - Removed (deprecated in PHP 8.0)
- **`ldap_sort()`** - Removed (deprecated in PHP 8.0)
- **`mysqli_get_client_info()` without parameters** - Removed (deprecated in PHP 8.1)
- **`mysqli_get_client_version()` without parameters** - Removed (deprecated in PHP 8.1)
- **`ReflectionClass::getStaticProperties()`** - Removed (deprecated in PHP 8.1)
- **`ReflectionClass::getStaticPropertyValue()`** - Removed (deprecated in PHP 8.1)
- **`ReflectionClass::setStaticPropertyValue()`** - Removed (deprecated in PHP 8.1)

#### **Functions Deprecated in PHP 8.4 (will be removed in PHP 9.0):**
- **`strtolower()` and `strtoupper()`** - Deprecated when used with non-ASCII characters (use `mb_strtolower()` / `mb_strtoupper()` instead)
- **`ucfirst()` and `lcfirst()`** - Deprecated when used with non-ASCII characters (use `mb_ucfirst()` / `mb_lcfirst()` instead)
- **`ucwords()`** - Deprecated when used with non-ASCII characters (use `mb_ucwords()` instead)
- **`htmlspecialchars()` and `htmlentities()`** - Deprecated when `$encoding` is not provided
- **`mb_convert_encoding()`** - Deprecated when `$from_encoding` is not provided
- **`iconv()`** - Deprecated when `$in_charset` is not provided
- **`utf8_encode()` and `utf8_decode()`** - Already deprecated, will be removed in PHP 9.0

#### **Behavioral Changes:**
- **`implode()`** - Now requires at least one parameter (previously could be called with 0 parameters)
- **`array_merge()`** - Stricter type checking
- **`json_encode()`** - Stricter error handling
- **`preg_match()`** - Stricter pattern validation

#### **Impact on Laravel:**
- **Low Impact**: Most Laravel code uses modern PHP functions and won't be affected
- **Potential Issues**: 
  - Custom code using deprecated functions (especially string functions with non-ASCII)
  - Legacy packages that haven't been updated
  - Direct use of removed functions in application code
- **Solution**: 
  - Deprecation warnings are suppressed in `docker/php/local.ini`
  - Most Laravel framework code is compatible
  - Update custom code gradually if needed

## Solutions Without Changing Code

### ✅ Solution 1: Suppress Deprecation Warnings (Already Configured)
The `docker/php/local.ini` file is configured to suppress deprecation warnings:
```ini
error_reporting=E_ALL & ~E_DEPRECATED & ~E_USER_DEPRECATED & ~E_STRICT
```

### Laravel Framework Compatibility
- Laravel 7-8: Designed for PHP 7.4-8.1
- Laravel 9: Requires PHP 8.0-8.2
- Laravel 10: Requires PHP 8.1-8.2
- Laravel 11: Requires PHP 8.2+
- Laravel 12: Requires PHP 8.2+

Most Laravel code will work with PHP 8.4, but you may see deprecation warnings.

## Current Configuration

- **PHP Version**: Using `dunglas/frankenphp:latest` (likely PHP 8.4)
- **Deprecation Warnings**: Suppressed in `docker/php/local.ini`
- **Compatibility**: Most PHP 8.1 code will work, warnings are hidden

## Recommendation

1. **For new projects**: Use PHP 8.2+ and Laravel 10+
2. **For existing PHP 8.1 code**: 
   - Keep using it with PHP 8.4 (warnings are suppressed)
   - Or switch to PHP 8.1/8.2 if needed (modify Dockerfile)
3. **Best practice**: Gradually update code to be PHP 8.4 compatible, but it's not urgent since warnings are suppressed

## Testing

After making changes, restart the container:
```bash
docker-compose restart app
# or
podman compose restart app
```

