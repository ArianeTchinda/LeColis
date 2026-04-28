/**
 * Constantes du module Subscription.
 */

const SUBSCRIPTION_STATUS = {
  ACTIVE:    'active',
  EXPIRED:   'expired',
  CANCELLED: 'cancelled',
  PENDING:   'pending',
};

const PAYMENT_METHODS = {
  MOBILE_MONEY:  'mobile_money',
  ORANGE_MONEY:  'orange_money',
  MTN_MOMO:      'mtn_momo',
  CARD:          'card',
};

module.exports = { SUBSCRIPTION_STATUS, PAYMENT_METHODS };
