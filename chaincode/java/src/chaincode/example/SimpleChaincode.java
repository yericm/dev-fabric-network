package chaincode.example;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import lombok.extern.slf4j.Slf4j;
import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ResponseUtils;

@Slf4j
public class SimpleChaincode extends ChaincodeBase {

	@Override
	public Response init(ChaincodeStub stub) {
		return ResponseUtils.newSuccessResponse("chaincode 实例化");
	}

	@Override
	public Response invoke(ChaincodeStub stub) {
		String func = stub.getFunction();
		List<String> args = stub.getParameters();
		try {
			if ("get".equals(func)) {
				String value = get(stub, args.get(0));
				return ResponseUtils.newSuccessResponse(value, value.getBytes(StandardCharsets.UTF_8));
			}
			if ("put".equals(func)) {
				put(stub, args.get(0), args.get(1));
				String txId = "OK: " + stub.getTxId();
				return ResponseUtils.newSuccessResponse(txId, txId.getBytes(StandardCharsets.UTF_8));
			}
		} catch (Exception e) {
		    log.error("unknown error: ", e);
		}
		String errmsg = "usage: <get/put> <keys> [value]";
		return ResponseUtils.newErrorResponse(errmsg, errmsg.getBytes(StandardCharsets.UTF_8));
	}

	private String get(ChaincodeStub stub, String keys) {
		return stub.getStringState(parseKey(stub, keys));
	}

	private void put(ChaincodeStub stub, String keys, String value) {
		stub.putStringState(parseKey(stub, keys), value);
	}

	private String parseKey(ChaincodeStub stub, String keys) {
		List<String> keyList = Arrays.stream(keys.split(",")).map(String::trim).filter(str->!str.isEmpty()).collect(Collectors.toList());
		if (keyList.size() == 1) {
			return keyList.get(0);
		} else {
			List<String> keyList1 = new ArrayList<>();
			for (int i = 1; i < keyList.size(); i++) {
				keyList1.add(keyList.get(i));
			}
			return stub.createCompositeKey(keyList.get(0), keyList1.toArray(new String[0])).toString();
		}
	}

	public static void main(String[] args) {
		new SimpleChaincode().start(args);
	}
}
