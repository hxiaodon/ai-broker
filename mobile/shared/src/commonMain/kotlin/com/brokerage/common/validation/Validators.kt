package com.brokerage.common.validation

import com.brokerage.common.decimal.BigDecimal

/**
 * Input validation utilities for trading application
 */

/**
 * Validation result
 */
sealed class ValidationResult {
    object Valid : ValidationResult()
    data class Invalid(val message: String) : ValidationResult()
}

fun ValidationResult.isValid(): Boolean = this is ValidationResult.Valid
fun ValidationResult.errorMessage(): String? = (this as? ValidationResult.Invalid)?.message

/**
 * Stock symbol validation
 */
object SymbolValidator {
    /**
     * Validate US stock symbol (1-5 uppercase letters)
     * Examples: AAPL, GOOGL, TSLA
     */
    fun validateUSSymbol(symbol: String): ValidationResult {
        if (symbol.isBlank()) {
            return ValidationResult.Invalid("Symbol cannot be empty")
        }
        if (!symbol.matches(Regex("^[A-Z]{1,5}$"))) {
            return ValidationResult.Invalid("US stock symbol must be 1-5 uppercase letters")
        }
        return ValidationResult.Valid
    }

    /**
     * Validate HK stock symbol (4-5 digits)
     * Examples: 0700, 09988, 00001
     */
    fun validateHKSymbol(symbol: String): ValidationResult {
        if (symbol.isBlank()) {
            return ValidationResult.Invalid("Symbol cannot be empty")
        }
        if (!symbol.matches(Regex("^\\d{4,5}$"))) {
            return ValidationResult.Invalid("HK stock symbol must be 4-5 digits")
        }
        return ValidationResult.Valid
    }

    /**
     * Auto-detect and validate symbol
     */
    fun validateSymbol(symbol: String): ValidationResult {
        val trimmed = symbol.trim().uppercase()
        return when {
            trimmed.matches(Regex("^[A-Z]{1,5}$")) -> validateUSSymbol(trimmed)
            trimmed.matches(Regex("^\\d{4,5}$")) -> validateHKSymbol(trimmed)
            else -> ValidationResult.Invalid("Invalid symbol format")
        }
    }
}

/**
 * Order quantity validation
 */
object QuantityValidator {
    /**
     * Validate order quantity
     * @param quantity Order quantity
     * @param minQuantity Minimum allowed quantity (default: 1)
     * @param maxQuantity Maximum allowed quantity (default: 1,000,000)
     * @param allowFractional Allow fractional shares (default: false)
     */
    fun validate(
        quantity: BigDecimal,
        minQuantity: BigDecimal = BigDecimal.ONE,
        maxQuantity: BigDecimal = BigDecimal(1_000_000),
        allowFractional: Boolean = false
    ): ValidationResult {
        if (quantity <= BigDecimal.ZERO) {
            return ValidationResult.Invalid("Quantity must be positive")
        }

        if (quantity < minQuantity) {
            return ValidationResult.Invalid("Quantity must be at least $minQuantity")
        }

        if (quantity > maxQuantity) {
            return ValidationResult.Invalid("Quantity cannot exceed $maxQuantity")
        }

        if (!allowFractional && quantity.stripTrailingZeros().scale() > 0) {
            return ValidationResult.Invalid("Fractional shares not allowed")
        }

        return ValidationResult.Valid
    }

    /**
     * Validate HK stock quantity (must be in board lots)
     * @param quantity Order quantity
     * @param boardLot Board lot size (e.g., 100, 500)
     */
    fun validateHKBoardLot(quantity: BigDecimal, boardLot: Int): ValidationResult {
        if (quantity <= BigDecimal.ZERO) {
            return ValidationResult.Invalid("Quantity must be positive")
        }

        if (quantity.stripTrailingZeros().scale() > 0) {
            return ValidationResult.Invalid("Quantity must be a whole number")
        }

        val quantityInt = quantity.toInt()
        if (quantityInt % boardLot != 0) {
            return ValidationResult.Invalid("Quantity must be in multiples of $boardLot (board lot)")
        }

        return ValidationResult.Valid
    }
}

/**
 * Price validation
 */
object PriceValidator {
    /**
     * Validate order price
     * @param price Order price
     * @param minPrice Minimum allowed price (default: 0.0001)
     * @param maxPrice Maximum allowed price (default: 1,000,000)
     * @param maxDecimalPlaces Maximum decimal places (default: 4 for US, 3 for HK)
     */
    fun validate(
        price: BigDecimal,
        minPrice: BigDecimal = BigDecimal("0.0001"),
        maxPrice: BigDecimal = BigDecimal(1_000_000),
        maxDecimalPlaces: Int = 4
    ): ValidationResult {
        if (price <= BigDecimal.ZERO) {
            return ValidationResult.Invalid("Price must be positive")
        }

        if (price < minPrice) {
            return ValidationResult.Invalid("Price must be at least $minPrice")
        }

        if (price > maxPrice) {
            return ValidationResult.Invalid("Price cannot exceed $maxPrice")
        }

        val scale = price.stripTrailingZeros().scale()
        if (scale > maxDecimalPlaces) {
            return ValidationResult.Invalid("Price cannot have more than $maxDecimalPlaces decimal places")
        }

        return ValidationResult.Valid
    }

    /**
     * Validate US stock price (max 4 decimal places)
     */
    fun validateUSPrice(price: BigDecimal): ValidationResult {
        return validate(price, maxDecimalPlaces = 4)
    }

    /**
     * Validate HK stock price (max 3 decimal places)
     */
    fun validateHKPrice(price: BigDecimal): ValidationResult {
        return validate(price, maxDecimalPlaces = 3)
    }
}

/**
 * Amount validation
 */
object AmountValidator {
    /**
     * Validate fund transfer amount
     * @param amount Transfer amount
     * @param minAmount Minimum allowed amount
     * @param maxAmount Maximum allowed amount
     */
    fun validate(
        amount: BigDecimal,
        minAmount: BigDecimal = BigDecimal.ONE,
        maxAmount: BigDecimal = BigDecimal(1_000_000)
    ): ValidationResult {
        if (amount <= BigDecimal.ZERO) {
            return ValidationResult.Invalid("Amount must be positive")
        }

        if (amount < minAmount) {
            return ValidationResult.Invalid("Amount must be at least $minAmount")
        }

        if (amount > maxAmount) {
            return ValidationResult.Invalid("Amount cannot exceed $maxAmount")
        }

        // Currency amounts should have max 2 decimal places
        val scale = amount.stripTrailingZeros().scale()
        if (scale > 2) {
            return ValidationResult.Invalid("Amount cannot have more than 2 decimal places")
        }

        return ValidationResult.Valid
    }
}

/**
 * Account validation
 */
object AccountValidator {
    /**
     * Validate email
     */
    fun validateEmail(email: String): ValidationResult {
        if (email.isBlank()) {
            return ValidationResult.Invalid("Email cannot be empty")
        }
        if (!email.matches(Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"))) {
            return ValidationResult.Invalid("Invalid email format")
        }
        return ValidationResult.Valid
    }

    /**
     * Validate password strength
     */
    fun validatePassword(password: String): ValidationResult {
        if (password.length < 8) {
            return ValidationResult.Invalid("Password must be at least 8 characters")
        }
        if (!password.any { it.isUpperCase() }) {
            return ValidationResult.Invalid("Password must contain at least one uppercase letter")
        }
        if (!password.any { it.isLowerCase() }) {
            return ValidationResult.Invalid("Password must contain at least one lowercase letter")
        }
        if (!password.any { it.isDigit() }) {
            return ValidationResult.Invalid("Password must contain at least one digit")
        }
        return ValidationResult.Valid
    }

    /**
     * Validate phone number (simple validation)
     */
    fun validatePhone(phone: String): ValidationResult {
        val cleaned = phone.replace(Regex("[^0-9+]"), "")
        if (cleaned.length < 10) {
            return ValidationResult.Invalid("Phone number must be at least 10 digits")
        }
        return ValidationResult.Valid
    }
}
