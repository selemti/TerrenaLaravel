<?php

if (! function_exists('feature_enabled')) {
    /**
     * Simple feature flag helper.
     */
    function feature_enabled(string $flag): bool
    {
        $features = config('features', []);

        if (! is_array($features)) {
            return true;
        }

        if (array_key_exists($flag, $features)) {
            return (bool) $features[$flag];
        }

        return true;
    }
}
