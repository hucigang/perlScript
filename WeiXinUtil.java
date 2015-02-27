package com.ruichibao.xpa.weixin.util;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.ConnectException;
import java.net.URL;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
 










import net.sf.json.JSONException;
import net.sf.json.JSONObject;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;

import com.ruichibao.xpa.common.util.AirScapeApplicationContext;
import com.ruichibao.xpa.web.view.util.MediaKit;
import com.ruichibao.xpa.weixin.model.UserBindInfo;
import com.ruichibao.xpa.weixin.model.WeixinOauth2Token;
import com.ruichibao.xpa.weixin.resp.Article;

 

public class WeiXinUtil {

	private static Logger log = Logger.getLogger(WeiXinUtil.class);
 

	/**
	 * 发起https请求并获取结果
	 * 
	 * @param requestUrl
	 * @param requestMethod
	 * @param outputStr
	 * @return
	 */
	public static JSONObject httpsRequest(String requestUrl,
			String requestMethod, String outputStr) {
		JSONObject jsonObject = null;
		StringBuffer buffer = new StringBuffer();
		System.out.println("requestUrl=" + requestUrl + ",requestMethod="
				+ requestMethod + ",outputStr=" + outputStr);
		try {
			log.fatal(requestUrl);
			// 创建SSLContext对象，并使用我们指定的信任管理器初始化
			TrustManager[] tm = { new MyX509TrustManager() };
			SSLContext sslContext = SSLContext.getInstance("SSL", "SunJSSE");
			sslContext.init(null, tm, new java.security.SecureRandom());
			// 从上述SSLContext对象中得到SSLSocketFactory对象
			SSLSocketFactory ssf = sslContext.getSocketFactory();

			URL url = new URL(requestUrl);
			HttpsURLConnection httpUrlConn = (HttpsURLConnection) url
					.openConnection();
			httpUrlConn.setSSLSocketFactory(ssf);

			httpUrlConn.setDoOutput(true);
			httpUrlConn.setDoInput(true);
			httpUrlConn.setUseCaches(false);
			// 设置请求方式（GET/POST）
			httpUrlConn.setRequestMethod(requestMethod);

			if ("GET".equalsIgnoreCase(requestMethod))
				httpUrlConn.connect();

			// 当有数据需要提交时
			if (null != outputStr) {
				OutputStream outputStream = httpUrlConn.getOutputStream();
				// 注意编码格式，防止中文乱码
				outputStream.write(outputStr.getBytes("UTF-8"));
				outputStream.close();
			}

			// 将返回的输入流转换成字符串
			InputStream inputStream = httpUrlConn.getInputStream();
			InputStreamReader inputStreamReader = new InputStreamReader(
					inputStream, "utf-8");
			BufferedReader bufferedReader = new BufferedReader(
					inputStreamReader);

			String str = null;
			while ((str = bufferedReader.readLine()) != null) {
				buffer.append(str);
			}
			bufferedReader.close();
			inputStreamReader.close();
			// 释放资源
			inputStream.close();
			inputStream = null;
			httpUrlConn.disconnect();
			jsonObject = JSONObject.fromObject(buffer.toString());
		} catch (ConnectException ce) {
			log.error("Weixin server connection timed out.");
		} catch (Exception e) {
			log.error("https request error:{}", e);
		}
		return jsonObject;
	}

	/**
	 * 发起http请求并获取结果
	 * 
	 * @param requestUrl
	 * @param requestMethod
	 * @param outputStr
	 * @return
	 */
	// public boolean httpRequest(String requestUrl,
	// String requestMethod, String appId) {
	// // StringBuffer buffer = new StringBuffer();
	// String result = null;
	// try {
	// log.fatal(requestUrl);
	//
	// URL url = new URL(requestUrl);
	// HttpURLConnection httpUrlConn = (HttpURLConnection) url
	// .openConnection();
	// httpUrlConn.setDoOutput(true);
	// httpUrlConn.setDoInput(true);
	// httpUrlConn.setUseCaches(false);
	// // 设置请求方式（GET/POST）
	// httpUrlConn.setRequestMethod(requestMethod);
	//
	// if ("GET".equalsIgnoreCase(requestMethod))
	// httpUrlConn.connect();
	//
	// // 将返回的输入流转换成字符串
	// InputStream inputStream = httpUrlConn.getInputStream();
	//
	// String filename =
	// httpUrlConn.getHeaderField("Content-disposition").split(";")[1].split("=")[1];
	// log.fatal("filename========"+httpUrlConn.getHeaderField("Content-disposition")+"====================="+filename);
	// String surffix = "." + FilenameUtils.getExtension(filename);
	// //String mtype = event.getFile().getContentType();
	//
	// File file;
	// String uploadUrl;
	// String tmpName = String.valueOf(System.currentTimeMillis());
	// try {
	// file = File.createTempFile(tmpName,surffix);
	// FileUtils.copyInputStreamToFile(inputStream,
	// file);
	// log.debug(file.getAbsolutePath());
	// log.debug(file.getName());
	//
	// uploadUrl = MediaKit.uploadSingle(file.getAbsolutePath(), appId);
	//
	// file.delete();
	//
	// MediaData md = new MediaData();
	//
	// md.setModule(appId);
	// md.setName(filename);
	// md.setMimeType(surffix);
	// md.setUrl(uploadUrl);
	// boolean ret = mediaService.saveNewMedia(md);
	// return ret;
	//
	// } catch (IOException e) {
	// // TODO Auto-generated catch block
	// e.printStackTrace();
	// }
	// // InputStreamReader inputStreamReader = new InputStreamReader(
	// // inputStream, "utf-8");
	// // BufferedReader bufferedReader = new BufferedReader(
	// // inputStreamReader);
	// //
	// // String str = null;
	// // while ((str = bufferedReader.readLine()) != null) {
	// // buffer.append(str);
	// // }
	// // bufferedReader.close();
	// // inputStreamReader.close();
	// // // 释放资源
	// // inputStream.close();
	// // inputStream = null;
	// // httpUrlConn.disconnect();
	// // result = buffer.toString();
	// } catch (ConnectException ce) {
	// log.error("Weixin server connection timed out.");
	// } catch (Exception e) {
	// log.error("https request error:{}", e);
	// }
	// return false;
	// }

	/*
	 * public static String WeixinArticleUs(String fromUserName, String
	 * toUserName) { String respMessage = null; NewsMessage newsMessage = new
	 * NewsMessage(); newsMessage.setToUserName(fromUserName);
	 * newsMessage.setFromUserName(toUserName); newsMessage.setCreateTime(new
	 * Date().getTime());
	 * newsMessage.setMsgType(MessageUtil.RESP_MESSAGE_TYPE_NEWS);
	 * newsMessage.setFuncFlag(0);
	 * 
	 * List<Article> articleList = new ArrayList<Article>();
	 * 
	 * Article article = new Article(); article.setTitle("关于我们");
	 * article.setDescription("贝贝贷........."); article.setPicUrl("");
	 * article.setUrl("http://demo.richbridge.cn/weixin/help/aboutus.jsf");
	 * articleList.add(article); // 设置图文消息个数
	 * newsMessage.setArticleCount(articleList.size()); // 设置图文消息包含的图文集合
	 * newsMessage.setArticles(articleList); // 将图文消息对象转换成xml字符串 return
	 * respMessage = MessageUtil.newsMessageToXml(newsMessage); }
	 * 
	 * public static String WeixinArticleIntroduction(String fromUserName,
	 * String toUserName) { String respMessage = null; NewsMessage newsMessage =
	 * new NewsMessage(); newsMessage.setToUserName(fromUserName);
	 * newsMessage.setFromUserName(toUserName); newsMessage.setCreateTime(new
	 * Date().getTime());
	 * newsMessage.setMsgType(MessageUtil.RESP_MESSAGE_TYPE_NEWS);
	 * newsMessage.setFuncFlag(0);
	 * 
	 * List<Article> articleList = new ArrayList<Article>(); String url =
	 * MessageKit.getMessage("system_url");
	 * 
	 * 1. 公司介绍：链接：http://www.bbdai.cn/m/help/aboutus.jsf 2.
	 * 服务平台：链接：http://www.bbdai.cn/m/index.jsf 3.
	 * 我要借款：链接：http://www.bbdai.cn/m/loan/apply.jsf 4.
	 * 我要投资：链接：http://www.bbdai.cn/m/loan/loanList.jsf
	 * 
	 * Article article1 = new Article(); article1.setTitle("公司介绍");
	 * article1.setDescription("瑞驰宝"); article1.setPicUrl(url +
	 * "/weixin/image/richbridge.jpg"); article1.setUrl(url +
	 * "/weixin/help/aboutus.jsf"); articleList.add(article1);
	 * 
	 * Article article2 = new Article(); article2.setTitle("投融资服务平台");
	 * article2.setDescription("贝贝贷"); article2.setPicUrl(url +
	 * "/weixin/image/mobile.jpg"); article2.setUrl(url + "/weixin/index.jsf");
	 * articleList.add(article2);
	 * 
	 * Article article3 = new Article(); article3.setTitle("立即申请借款");
	 * article3.setDescription("立即申请借款"); article3.setPicUrl(url +
	 * "/weixin/image/loan.jpg"); article3.setUrl(url +
	 * "/weixin/loan/apply.jsf"); articleList.add(article3);
	 * 
	 * Article article4 = new Article(); article4.setTitle("投资理财");
	 * article4.setDescription("投资理财"); article4.setPicUrl(url +
	 * "/weixin/image/investment.jpg"); article4.setUrl(url +
	 * "/weixin/loan/loanList.jsf"); articleList.add(article4);
	 * 
	 * // 设置图文消息个数 newsMessage.setArticleCount(articleList.size()); //
	 * 设置图文消息包含的图文集合 newsMessage.setArticles(articleList); // 将图文消息对象转换成xml字符串
	 * return respMessage = MessageUtil.newsMessageToXml(newsMessage); }
	 */

	public static boolean sendMessage(String openId, String content,
			String access_token) {

		String jsonMsg = WeiXinUtil.makeTextCustomMessage(openId, content);
		return WeiXinUtil.sendCustomMessage(access_token, jsonMsg);

	}

	/**
	 * 组装文本客服消息
	 */
	public static String makeTextCustomMessage(String openId, String content) {
		// 对消息内容中的双引号转义
		content = content.replace("\"", "\\\"");
		String jsonMsg = "{\"touser\":\"%s\",\"msgtype\":\"text\",\"text\":{\"content\":\"%s\"}}";
		return String.format(jsonMsg, openId, content);
	}

	public static String makeArticleMessage(String openId, Article arc) {
		String jsonMsg = "{\"touser\":\"%s\",\"msgtype\":\"news\",\"news\":{\"articles\": [{\"title\":\"%s\",\"description\":\"%s\",\"url\":\"%s\",\"picurl\":\"%s\"}]}}";
		// System.out.println(jsonMsg.toString());
		return String.format(jsonMsg, openId, arc.getTitle(),
				arc.getDescription(), arc.getUrl(), arc.getPicUrl());
	}

	/**
	 * 发送客服消息
	 */

	public static boolean sendCustomMessage(String accessToken, String jsonMsg) {
		boolean result = false;
		System.out.println("jsonMsg:" + jsonMsg);
		// 拼接请求地址
		String requestUrl = "https://api.weixin.qq.com/cgi-bin/message/custom/send?access_token=ACCESS_TOKEN";
		requestUrl = requestUrl.replace("ACCESS_TOKEN", accessToken);
		// 发送客服消息
		JSONObject jsonObject = WeiXinUtil.httpsRequest(requestUrl, "POST",
				jsonMsg);

		if (null != jsonObject) {
			int errorCode = jsonObject.getInt("errcode");
			String errorMsg = jsonObject.getString("errmsg");
			System.out.println("errcode:" + errorCode + "\terrmsg:" + errorMsg);
			if (0 == errorCode) {
				result = true;
			}

		}
		System.out.println("jsonObject is null");
		return result;

	}

	// 获取access_token的接口地址（GET） 限200（次/天）
	public final static String access_token_url = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=APPID&secret=APPSECRET";

	/**
	 * 获取access_token，业务模块禁止直接调用，必须通过ConsultService接口获取。
	 * 
	 * @param appid
	 *            凭证
	 * @param appsecret
	 *            密钥
	 * @return
	 */
	public static String getAccessToken() {
		String accessToken = null;
		WeixinConfiguration wc = AirScapeApplicationContext.getBean(
				"WeixinConfig", WeixinConfiguration.class);

		String requestUrl = access_token_url.replace("APPID", wc.getAppId())
				.replace("APPSECRET", wc.getAppSecret());
		JSONObject jsonObject = httpsRequest(requestUrl, "GET", null);
		// 如果请求成功
		if (null != jsonObject) {
			try {
				accessToken = jsonObject.getString("access_token");
			} catch (JSONException e) {
				accessToken = null;
				// 获取token失败
				log.error("获取token失败 errcode:{} errmsg:{}");
			}
		}
		return accessToken;
	}

	/*
	 * public static String WeixinArticleActivity(String fromUser, String
	 * toUser, Activity activity) { String respMessage = null; NewsMessage
	 * newsMessage = new NewsMessage(); newsMessage.setToUserName(fromUser);
	 * newsMessage.setFromUserName(toUser); newsMessage.setCreateTime(new
	 * Date().getTime());
	 * newsMessage.setMsgType(MessageUtil.RESP_MESSAGE_TYPE_NEWS);
	 * newsMessage.setFuncFlag(0);
	 * 
	 * List<Article> articleList = new ArrayList<Article>();
	 * System.out.println(articleList.size()); String url =
	 * MessageKit.getMessage("system_url");
	 * 
	 * Article article = new Article(); article.setTitle(activity.getTitle());
	 * article.setDescription(activity.getDescription());
	 * article.setPicUrl(activity.getPath()); article.setUrl(url +
	 * "/weixin/activity/activityId" + activity.getActivityType() + ".jsf" +
	 * "?activityId=" + activity.getId()); articleList.add(article);
	 * 
	 * // 设置图文消息个数 newsMessage.setArticleCount(articleList.size()); //
	 * 设置图文消息包含的图文集合 newsMessage.setArticles(articleList); // 将图文消息对象转换成xml字符串
	 * return respMessage = MessageUtil.newsMessageToXml(newsMessage); }
	 */

	private static String oauth2Url = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=APPID&redirect_uri=REDIRECT_URI&response_type=code&scope=snsapi_base&state=STATE#wechat_redirect";

	public static String getOAuthURL(String appUrl, String state) {
		WeixinConfiguration wc = AirScapeApplicationContext.getBean(
				"WeixinConfig", WeixinConfiguration.class);

		String appUri = MediaKit.URLEncode(appUrl);
		String retUrl = oauth2Url;
		return retUrl.replace("APPID", wc.getAppId())
				.replace("REDIRECT_URI", appUri).replace("STATE", state);
	}

	/**
	 * 获取网页授权凭证
	 * 
	 * @param appId
	 * @param appSecret
	 * @param code
	 * @return
	 */
	public static WeixinOauth2Token getOauth2AccessToken(String code) {
		WeixinOauth2Token wat = null;
		// 拼接请求地址
		String requestUrl = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=APPID"
				+ "&secret=SECRET&code=CODE&grant_type=authorization_code";

		WeixinConfiguration wc = AirScapeApplicationContext.getBean(
				"WeixinConfig", WeixinConfiguration.class);

		requestUrl = requestUrl.replace("APPID", wc.getAppId());
		requestUrl = requestUrl.replace("SECRET", wc.getAppSecret());
		requestUrl = requestUrl.replace("CODE", code);

		JSONObject jsonObject = httpsRequest(requestUrl, "GET", null);
		if (null != jsonObject) {
			try {
				wat = new WeixinOauth2Token();
				wat.setAccessToken(jsonObject.getString("access_token"));
				wat.setExpiresIn(jsonObject.getInt("expires_in"));
				wat.setOpenId(jsonObject.getString("openid"));
				wat.setRefreshToken(jsonObject.getString("refresh_token"));
				wat.setScope(jsonObject.getString("scope"));
			} catch (Exception e) {
				wat = null;
				int errorCode = jsonObject.getInt("errcode");
				String errorMsg = jsonObject.getString("errmsg");
				log.fatal("获取网页授权凭证失败  errcode:{" + errorCode + "} errmsg:{"
						+ errorMsg + "}");

			}
		}
		return wat;
	}

	/**
	 * 刷新网页授权凭证
	 * 
	 * @param appId
	 * @param refreshToken
	 * @return
	 */
	public static WeixinOauth2Token refreshOauth2AccessToken(String refreshToken) {
		WeixinOauth2Token wat = null;
		// 拼接请求地址
		String requestUrl = "https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=APPID"
				+ "&grant_type=refresh_token&refresh_token=REFRESH_TOKEN";
		WeixinConfiguration wc = AirScapeApplicationContext.getBean(
				"WeixinConfig", WeixinConfiguration.class);

		requestUrl = requestUrl.replace("APPID", wc.getAppId());
		requestUrl = requestUrl.replace("REFRESH_TOKEN", refreshToken);

		JSONObject jsonObject = httpsRequest(requestUrl, "GET", null);
		if (null != jsonObject) {
			try {
				wat = new WeixinOauth2Token();
				wat.setAccessToken(jsonObject.getString("access_token"));
				wat.setExpiresIn(jsonObject.getInt("expires_in"));
				wat.setOpenId(jsonObject.getString("openid"));
				wat.setRefreshToken(jsonObject.getString("refresh_token"));
				wat.setScope(jsonObject.getString("scope"));
			} catch (Exception e) {
				wat = null;
				int errorCode = jsonObject.getInt("errcode");
				String errorMsg = jsonObject.getString("errmsg");
				log.fatal("获取网页授权凭证失败  errcode:{" + errorCode + "} errmsg:{"
						+ errorMsg + "}");

			}
		}
		return wat;
	}

	/**
	 * 通过网页授权获取用户信息
	 * 
	 * @param accessToken
	 * @param openId
	 * @return
	 */
	public static UserBindInfo getUserInfo(String accessToken, String openId) {
		UserBindInfo user = null;
		// 拼接请求地址
		String requestUrl = "https://api.weixin.qq.com/sns/userinfo?access_token=ACCESS_TOKEN&openid=OPENID&lang=zh_CN";
		requestUrl = requestUrl.replace("ACCESS_TOKEN", accessToken).replace(
				"OPENID", openId);
		JSONObject jsonObject = httpsRequest(requestUrl, "GET", null);
		if (null != jsonObject) {
			try {
				user = new UserBindInfo();
				user.setBindId(jsonObject.getString("openid"));
				user.setNickName(jsonObject.getString("nickname"));
				user.setSex(jsonObject.getInt("sex"));
				user.setCity(jsonObject.getString("city"));
				user.setCountry(jsonObject.getString("country"));
				user.setProvince(jsonObject.getString("province"));
				user.setHeadImgUrl(jsonObject.getString("headimgurl"));
			} catch (Exception e) {
				user = null;
				int errorCode = jsonObject.getInt("errcode");
				String errorMsg = jsonObject.getString("errmsg");
				log.fatal("获取网页授权凭证失败  errcode:{" + errorCode + "} errmsg:{"
						+ errorMsg + "}");

			}
		}
		log.fatal("user==================" + user);
		return user;
	}

	static final String OAUTH2_URL = "https://open.weixin.qq.com/connect/oauth2/authorize?appid=APPID&redirect_uri=REDIRECT_URI&response_type=code&scope=SCOPE&state=STATE#wechat_redirect";

	public static String replaceToOAuthURL(String url) {
		WeixinConfiguration wc = AirScapeApplicationContext.getBean(
				"WeixinConfig", WeixinConfiguration.class);
		String tmpUrl = MediaKit.URLEncode(url);
		return OAUTH2_URL.replace("APPID", wc.getAppId())
				.replace("REDIRECT_URI", tmpUrl)
				.replace("SCOPE", "snsapi_base");
	}

}
