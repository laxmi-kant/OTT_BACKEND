package com.ottnetwork.kafka;

public final class KafkaTopics {

    private KafkaTopics() {}

    // Auth events
    public static final String OTP_REQUESTED = "ott.auth.otp-requested";
    public static final String USER_REGISTERED = "ott.user.registered";
    public static final String AUTH_LOGIN = "ott.auth.login";

    // User events
    public static final String USER_PROFILE_UPDATED = "ott.user.profile-updated";
    public static final String USER_DELETED = "ott.user.deleted";

    // Content events
    public static final String CONTENT_UPLOAD_COMPLETED = "ott.content.upload-completed";
    public static final String CONTENT_PUBLISHED = "ott.content.content-published";
    public static final String CONTENT_UPDATED = "ott.content.content-updated";
    public static final String CONTENT_DELETED = "ott.content.content-deleted";
    public static final String CONTENT_IMAGE_UPLOADED = "ott.content.image-uploaded";

    // Video / streaming events
    public static final String TRANSCODE_COMPLETED = "ott.video.transcode-completed";
    public static final String TRANSCODE_FAILED = "ott.video.transcode-failed";
    public static final String STREAM_STARTED = "ott.stream.started";
    public static final String STREAM_ENDED = "ott.stream.ended";
    public static final String STREAM_PROGRESS = "ott.stream.progress";

    // Subscription events
    public static final String SUBSCRIPTION_CREATED = "ott.subscription.created";
    public static final String SUBSCRIPTION_CANCELLED = "ott.subscription.cancelled";
    public static final String SUBSCRIPTION_EXPIRED = "ott.subscription.expired";
    public static final String PAYMENT_PROCESSED = "ott.payment.processed";
    public static final String PAYMENT_FAILED = "ott.payment.failed";

    // Engagement events
    public static final String WATCHLIST_ADDED = "ott.watchlist.added";
    public static final String SOCIAL_RATING_ADDED = "ott.social.rating-added";

    // Ad events
    public static final String AD_IMPRESSION = "ott.ad.impression";
    public static final String AD_COMPLETE = "ott.ad.complete";
}
