/**
 * ---------------------------------------------------
 * File:    JsonUtil
 * Package: chaincode.example
 * Project: my_java_chaincode
 * ---------------------------------------------------
 * Author: gavinguan
 * Create: 2020/1/21 10:28 上午.
 * Copyright © 2020 gavinguan. All rights reserved.
 */
package chaincode.example;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.NonNull;

import java.io.IOException;

public class JsonUtil {

    public static final ObjectMapper JSON_MAPPER;

    static {
        ObjectMapper objectMapper = new ObjectMapper();
        // 反序列化时, 如果在 java class 中无法找到对应的属性, 忽略ta
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        JSON_MAPPER = objectMapper;
    }

    // 对象 转 json
    public static String object2Json(@NonNull Object object) {
        try {
            return JSON_MAPPER.writeValueAsString(object);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    // json 转 对象
    public static <T> T json2Object(@NonNull String json, @NonNull Class<T> clazz) {
        try {
            return JSON_MAPPER.readValue(json, clazz);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
