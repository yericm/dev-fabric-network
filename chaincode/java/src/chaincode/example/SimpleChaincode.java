package chaincode.example;

import java.nio.charset.StandardCharsets;
import java.util.List;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.hyperledger.fabric.shim.ChaincodeBase;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ResponseUtils;

public class SimpleChaincode extends ChaincodeBase {

	private static Log _logger = LogFactory.getLog(SimpleChaincode.class);
	
	@Override
	public Response init(ChaincodeStub stub) {
		return ResponseUtils.newSuccessResponse("chaincode 实例化");
	}

	@Override
	public Response invoke(ChaincodeStub stub) {
		String function = stub.getFunction();
		List<String> parameters = stub.getParameters();
		StringBuilder sb = new StringBuilder();
		sb.append("链码调用 [func:");
		sb.append(function);
		sb.append(", ");
		sb.append("args: ");
		for (int i = 0; i < parameters.size(); i++) {
			String item = parameters.get(i);
		    sb.append(item);
		    if (parameters.size() - 1 != i) {
				sb.append(", ");
			}
		}
		sb.append("]");
		String msg = sb.toString();
		return ResponseUtils.newSuccessResponse(msg, msg.getBytes(StandardCharsets.UTF_8));
	}


	public static void main(String[] args) {
		new SimpleChaincode().start(args);
	}
}
